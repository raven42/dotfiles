#!/usr/bin/env bash

set -euo pipefail

GIT_SETUP_USER="${GIT_SETUP_USER:-raven42}"
GIT_SETUP_NAME="${GIT_SETUP_NAME:-David Hegland}"
GIT_SETUP_EMAIL="${GIT_SETUP_EMAIL:-darth.gerbil@gmail.com}"
# Proxmox supplies ADMIN_USER. Standalone usage configures the invoking account.
TARGET_USER="${ADMIN_USER:-${SUDO_USER:-$(id -un)}}"

die() {
    printf 'ERROR: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: git-setup.sh [--user <git-username>] [--name <real-name>] [--email <email>]

Defaults:
  --user   raven42
  --name   David Hegland
  --email  darth.gerbil@gmail.com

Sets user.username, user.name, user.email, and alias.glog in global Git config.
user.username is informational; it does not configure Git authentication.
ADMIN_USER selects the Linux account (otherwise the invoking/sudo account).
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --user|--name|--email)
            [[ $# -ge 2 && -n "$2" && "$2" != -* ]] ||
                die "$1 requires a value."
            case "$1" in
                --user) GIT_SETUP_USER="$2" ;;
                --name) GIT_SETUP_NAME="$2" ;;
                --email) GIT_SETUP_EMAIL="$2" ;;
            esac
            shift 2
            ;;
        -h|--help) usage; exit 0 ;;
        *) die "Unknown option: $1" ;;
    esac
done

command -v git >/dev/null || die "Git is required; run the Debian baseline first."
id "${TARGET_USER}" &>/dev/null || die "Linux account does not exist: ${TARGET_USER}"
TARGET_HOME="$(getent passwd "${TARGET_USER}" | cut -d: -f6)"
[[ "${TARGET_HOME}" == /* && -d "${TARGET_HOME}" ]] ||
    die "Missing or invalid home directory for ${TARGET_USER}."
CURRENT_USER="$(id -un)"
if [[ "${TARGET_USER}" != "${CURRENT_USER}" ]]; then
    [[ "${EUID}" -eq 0 ]] || die "Run as root to configure another Linux account."
    command -v sudo >/dev/null || die "sudo is required to configure ${TARGET_USER}."
fi

git_for_user() {
    if [[ "${TARGET_USER}" == "${CURRENT_USER}" ]]; then
        HOME="${TARGET_HOME}" git "$@"
    else
        sudo -H -u "${TARGET_USER}" HOME="${TARGET_HOME}" git "$@"
    fi
}

git_for_user config --global --replace-all user.username "${GIT_SETUP_USER}"
git_for_user config --global --replace-all user.name "${GIT_SETUP_NAME}"
git_for_user config --global --replace-all user.email "${GIT_SETUP_EMAIL}"
git_for_user config --global --replace-all alias.glog \
    "log --graph --all --pretty=format:'%C(yellow)%h%Creset %C(red)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset'"

printf 'Git identity and glog alias configured for Linux account %s.\n' "${TARGET_USER}"
