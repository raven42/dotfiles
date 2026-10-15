#!/usr/bin/env bash

set -euo pipefail

ADMIN_USER="${ADMIN_USER:-raven}"
ADMIN_SHELL="${ADMIN_SHELL:-/bin/bash}"
ADMIN_SSH_KEY_FILE="${ADMIN_SSH_KEY_FILE:-/root/ssh_key.pub}"

ROOT_PASSWORD="${ROOT_PASSWORD:-}"

TIMEZONE="${TIMEZONE:-America/Chicago}"
LOCALE="${LOCALE:-en_US.UTF-8}"

BASE_PACKAGES=(
    bash-completion
    ca-certificates
    curl
    dnsutils
    git
    htop
    jq
    locales
    lsof
    nano
    net-tools
    openssh-server
    python3
    ripgrep
    rsync
    sudo
    tmux
    tree
    unzip
    vim
    wget
    zip
)

log() {
    printf '\n\033[1;34m==>\033[0m %s\n' "$*"
}

die() {
    printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2
    exit 1
}

require_root() {
    [[ "${EUID}" -eq 0 ]] ||
        die "This script must be run as root."
}

check_debian() {
    [[ -r /etc/os-release ]] ||
        die "/etc/os-release not found."

    # shellcheck disable=SC1091
    source /etc/os-release

    [[ "${ID:-}" == "debian" ]] ||
        die "This bootstrap is intended for Debian. Detected: ${ID:-unknown}"

    log "Detected Debian ${VERSION_ID:-unknown}"
}

update_system() {
    log "Updating package metadata"
    apt-get update

    log "Upgrading installed packages"

    DEBIAN_FRONTEND=noninteractive \
        apt-get -y full-upgrade
}

install_packages() {
    log "Installing baseline packages"

    DEBIAN_FRONTEND=noninteractive \
        apt-get install -y "${BASE_PACKAGES[@]}"
}

configure_locale() {
    log "Configuring locale: ${LOCALE}"

    if ! grep -Eq "^${LOCALE}[[:space:]]+UTF-8" /etc/locale.gen; then
        sed -i \
            -E "s|^#[[:space:]]*${LOCALE}[[:space:]]+UTF-8|${LOCALE} UTF-8|" \
            /etc/locale.gen
    fi

    locale-gen
    update-locale LANG="${LOCALE}"
}

configure_timezone() {
    log "Configuring timezone: ${TIMEZONE}"

    [[ -e "/usr/share/zoneinfo/${TIMEZONE}" ]] ||
        die "Invalid timezone: ${TIMEZONE}"

    timedatectl set-timezone "${TIMEZONE}"
}

configure_root_password() {
    if [[ -z "${ROOT_PASSWORD}" ]]; then
        log "No root password supplied; leaving root password unchanged"
        return
    fi

    log "Setting root password"

    printf 'root:%s\n' "${ROOT_PASSWORD}" |
        chpasswd
}

configure_admin_user() {
    local home
    local ssh_dir
    local authorized_keys
    local public_key

    log "Configuring admin user: ${ADMIN_USER}"

    if ! id "${ADMIN_USER}" &>/dev/null; then
        useradd \
            --create-home \
            --shell "${ADMIN_SHELL}" \
            "${ADMIN_USER}"
    fi

    usermod -s "${ADMIN_SHELL}" "${ADMIN_USER}"
    usermod -aG sudo "${ADMIN_USER}"

    home="$(getent passwd "${ADMIN_USER}" | cut -d: -f6)"
    ssh_dir="${home}/.ssh"
    authorized_keys="${ssh_dir}/authorized_keys"

    install -d \
        -m 0700 \
        -o "${ADMIN_USER}" \
        -g "${ADMIN_USER}" \
        "${ssh_dir}"

    if [[ -f "${ADMIN_SSH_KEY_FILE}" ]]; then
        public_key="$(cat "${ADMIN_SSH_KEY_FILE}")"

        touch "${authorized_keys}"

        if ! grep -qxF "${public_key}" "${authorized_keys}"; then
            printf '%s\n' "${public_key}" >> "${authorized_keys}"
        fi

        chown "${ADMIN_USER}:${ADMIN_USER}" "${authorized_keys}"
        chmod 0600 "${authorized_keys}"

        log "Installed SSH public key for ${ADMIN_USER}"
    else
        log "No SSH public key found; skipping"
    fi
}

configure_sudo() {
    local sudoers_file="/etc/sudoers.d/${ADMIN_USER}"

    log "Configuring sudo for ${ADMIN_USER}"

    cat > "${sudoers_file}" <<EOF
${ADMIN_USER} ALL=(ALL) NOPASSWD:ALL
EOF

    chmod 0440 "${sudoers_file}"
    visudo -cf "${sudoers_file}" >/dev/null
}

enable_services() {
    log "Enabling standard services"

    systemctl enable --now ssh
}

cleanup() {
    log "Cleaning package cache"

    apt-get -y autoremove
    apt-get clean
}

summary() {
    log "Bootstrap complete"

    printf '  Hostname:  %s\n' "$(hostname -f 2>/dev/null || hostname)"
    printf '  Debian:    %s\n' "$(. /etc/os-release && echo "${PRETTY_NAME}")"
    printf '  Timezone:  %s\n' "$(timedatectl show --property=Timezone --value)"
    printf '  Locale:    %s\n' "${LOCALE}"
    printf '  User:      %s\n' "${ADMIN_USER}"
}

main() {
    require_root
    check_debian
    update_system
    install_packages
    configure_locale
    configure_timezone
    configure_root_password
    configure_admin_user
    configure_sudo
    enable_services
    cleanup
    summary
}

main "$@"
