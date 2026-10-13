#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Debian infrastructure bootstrap
#
# Intended for small Debian servers/LXCs.
#
# Usage:
#   sudo ./sbin/bootstrap/debian.sh
#
# Optional overrides:
#   TIMEZONE=America/Chicago
#   LOCALE=en_US.UTF-8
#
# Example:
#   sudo TIMEZONE=America/Chicago ./sbin/bootstrap/debian.sh
# -----------------------------------------------------------------------------

ADMIN_USER="${ADMIN_USER:-raven}"
ADMIN_SHELL="${ADMIN_SHELL:-/bin/bash}"
ADMIN_SSH_KEY_FILE="${ADMIN_SSH_KEY_FILE:-/root/ssh_key.pub}"
ROOT_PASSWORD="${ROOT_PASSWORD:-}"

TIMEZONE="${TIMEZONE:-America/Chicago}"
LOCALE="${LOCALE:-en_US.UTF-8}"

INSTALL_DOTFILES=0

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

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dotfiles)
            INSTALL_DOTFILES=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            die "Unknown option: $1"
            ;;
    esac
done

log() {
    printf '\n\033[1;32m==>\033[0m %s\n' "$*"
}

die() {
    printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2
    exit 1
}

require_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        die "This script must be run as root or with sudo."
    fi
}

check_debian() {
    [[ -r /etc/os-release ]] || die "/etc/os-release not found."

    # shellcheck disable=SC1091
    source /etc/os-release

    if [[ "${ID:-}" != "debian" ]]; then
        die "This bootstrap is intended for Debian. Detected: ${ID:-unknown}"
    fi

    log "Detected Debian ${VERSION_ID:-unknown}"
}

update_system() {
    log "Updating package metadata"
    apt-get update

    log "Upgrading installed packages"
    DEBIAN_FRONTEND=noninteractive apt-get -y full-upgrade
}

install_packages() {
    log "Installing baseline packages"
    DEBIAN_FRONTEND=noninteractive apt-get install -y "${BASE_PACKAGES[@]}"
}

configure_locale() {
    log "Configuring locale: ${LOCALE}"

    local locale_entry="${LOCALE/UTF-8/UTF-8 UTF-8}"

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

    if [[ ! -e "/usr/share/zoneinfo/${TIMEZONE}" ]]; then
        die "Invalid timezone: ${TIMEZONE}"
    fi

    timedatectl set-timezone "${TIMEZONE}"
}

configure_admin_user() {
    log "Configuring admin user: ${ADMIN_USER}"

    if ! id "${ADMIN_USER}" &>/dev/null; then
        useradd \
            --create-home \
            --shell "${ADMIN_SHELL}" \
            "${ADMIN_USER}"
    fi

    usermod -s "${ADMIN_SHELL}" "${ADMIN_USER}"
    usermod -aG sudo "${ADMIN_USER}"

    local ssh_dir="/home/${ADMIN_USER}/.ssh"
    local auth_keys="${ssh_dir}/authorized_keys"

    install -d \
        -m 700 \
        -o "${ADMIN_USER}" \
        -g "${ADMIN_USER}" \
        "${ssh_dir}"

    if [[ -f "${ADMIN_SSH_KEY_FILE}" ]]; then
        install \
            -m 600 \
            -o "${ADMIN_USER}" \
            -g "${ADMIN_USER}" \
            "${ADMIN_SSH_KEY_FILE}" \
            "${auth_keys}"

        log "Installed SSH public key for ${ADMIN_USER}"
    else
        log "No SSH public key found at ${ADMIN_SSH_KEY_FILE}; skipping"
    fi
}

configure_root_password() {
    if [[ -z "${ROOT_PASSWORD}" ]]; then
        log "No root password supplied; leaving root password unchanged"
        return
    fi

    log "Setting root password"
    printf 'root:%s\n' "${ROOT_PASSWORD}" | chpasswd
}

configure_sudo() {
    log "Configuring sudo for ${ADMIN_USER}"

    cat > "/etc/sudoers.d/${ADMIN_USER}" <<EOF
${ADMIN_USER} ALL=(ALL) NOPASSWD:ALL
EOF

    chmod 0440 "/etc/sudoers.d/${ADMIN_USER}"
    visudo -cf "/etc/sudoers.d/${ADMIN_USER}" >/dev/null
}

configure_dotfiles() {
    local script_dir
    local dotfiles_script

    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
    dotfiles_script="${script_dir}/dotfiles.sh"

    [[ -x "${dotfiles_script}" ]] ||
        die "Dotfiles bootstrap not found or not executable: ${dotfiles_script}"

    log "Installing dotfiles for ${ADMIN_USER}"

    "${dotfiles_script}" \
        --user "${ADMIN_USER}"
}

enable_services() {
    log "Enabling standard services"

    if systemctl list-unit-files ssh.service &>/dev/null; then
        systemctl enable ssh.service
    fi

    if systemctl list-unit-files fstrim.timer &>/dev/null; then
        systemctl enable fstrim.timer
    fi
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

    if [[ "${INSTALL_DOTFILES}" -eq 1 ]]; then
        configure_dotfiles
    fi

    enable_services
    cleanup
    summary
}

main "$@"