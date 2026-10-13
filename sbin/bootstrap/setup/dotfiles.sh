#!/usr/bin/env bash

set -euo pipefail

ADMIN_USER="${ADMIN_USER:-}"

DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/raven42/dotfiles.git}"

log() {
    printf '\n==> %s\n' "$*"
}

die() {
    printf '\nERROR: %s\n' "$*" >&2
    exit 1
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user)
            ADMIN_USER="$2"
            shift 2
            ;;

        -h|--help)
            echo "Usage: $(basename "$0") [--user <username>]"
            exit 0
            ;;

        *)
            die "Unknown option: $1"
            ;;
    esac
done

[[ "${EUID}" -eq 0 ]] ||
    die "Run this script as root."

[[ -n "${ADMIN_USER}" ]] ||
    die "No user specified. Set ADMIN_USER or use --user."

id "${ADMIN_USER}" &>/dev/null ||
    die "User does not exist: ${ADMIN_USER}"

USER_HOME="$(getent passwd "${ADMIN_USER}" | cut -d: -f6)"
DOTFILES_DIR="${USER_HOME}/.cfg"
BACKUP_DIR="${USER_HOME}/.bak"
GLOBAL_IGNORE="${USER_HOME}/.gitignore_global"

githome() {
    sudo -u "${ADMIN_USER}" \
        HOME="${USER_HOME}" \
        git \
            --git-dir="${DOTFILES_DIR}" \
            --work-tree="${USER_HOME}" \
            "$@"
}

log "Preparing dotfiles environment for ${ADMIN_USER}"

install -d \
    -o "${ADMIN_USER}" \
    -g "${ADMIN_USER}" \
    "${BACKUP_DIR}" \
    "${USER_HOME}/tmp" \
    "${USER_HOME}/var/log"

for file in \
    .bashrc \
    .bash_profile \
    .profile \
    .vimrc
do
    source="${USER_HOME}/${file}"

    if [[ -e "${source}" && ! -L "${source}" ]]; then
        backup="${BACKUP_DIR}/${file#.}"

        if [[ ! -e "${backup}" ]]; then
            log "Backing up ${file}"
            mv "${source}" "${backup}"
            chown "${ADMIN_USER}:${ADMIN_USER}" "${backup}"
        fi
    fi
done

if [[ ! -d "${DOTFILES_DIR}" ]]; then
    log "Cloning dotfiles repository"

    sudo -u "${ADMIN_USER}" \
        HOME="${USER_HOME}" \
        git clone --bare \
        "${DOTFILES_REPO}" \
        "${DOTFILES_DIR}"
else
    log "Updating dotfiles repository"

    githome fetch origin
fi

touch "${GLOBAL_IGNORE}"

grep -qxF ".cfg" "${GLOBAL_IGNORE}" ||
    echo ".cfg" >> "${GLOBAL_IGNORE}"

grep -qxF "*.sw?" "${GLOBAL_IGNORE}" ||
    echo "*.sw?" >> "${GLOBAL_IGNORE}"

chown "${ADMIN_USER}:${ADMIN_USER}" "${GLOBAL_IGNORE}"

sudo -u "${ADMIN_USER}" \
    HOME="${USER_HOME}" \
    git config --global \
    core.excludesfile "${GLOBAL_IGNORE}"

githome config status.showUntrackedFiles no

log "Checking out dotfiles"

githome checkout

log "Dotfiles installed"
