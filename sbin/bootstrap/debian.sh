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
    enable_services
    cleanup
    summary
}

main "$@"