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
            [[ $# -ge 2 && -n "$2" && "$2" != -* ]] ||
                die "--user requires a username."
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

for command in git python3 sudo; do
    command -v "${command}" >/dev/null ||
        die "Missing prerequisite: ${command}. Run the current Debian baseline first."
done

USER_HOME="$(getent passwd "${ADMIN_USER}" | cut -d: -f6)"
[[ "${USER_HOME}" == /* && "${USER_HOME}" != / ]] ||
    die "Invalid home directory for ${ADMIN_USER}: ${USER_HOME}"
DOTFILES_DIR="${USER_HOME}/Projects/dotfiles"

as_user() {
    sudo -u "${ADMIN_USER}" HOME="${USER_HOME}" "$@"
}

log "Preparing standard dotfiles checkout for ${ADMIN_USER}"
install -d -o "${ADMIN_USER}" -g "$(id -gn "${ADMIN_USER}")" \
    "${USER_HOME}/Projects" "${USER_HOME}/tmp" "${USER_HOME}/var/log"
if [[ ! -e "${DOTFILES_DIR}" && ! -L "${DOTFILES_DIR}" ]]; then
    as_user git clone --recurse-submodules "${DOTFILES_REPO}" "${DOTFILES_DIR}"
else
    log "Using existing checkout without pulling or discarding local changes"
fi

[[ -d "${DOTFILES_DIR}" ]] || die "Not a checkout directory: ${DOTFILES_DIR}"
CHECKOUT_ROOT="$(as_user git -C "${DOTFILES_DIR}" rev-parse --show-toplevel)" ||
    die "Not a standard Git checkout: ${DOTFILES_DIR}"
[[ "$(cd -- "${CHECKOUT_ROOT}" && pwd -P)" == "$(cd -- "${DOTFILES_DIR}" && pwd -P)" ]] ||
    die "Expected a checkout rooted at ${DOTFILES_DIR}, not a directory inside another repository."
for file in setup.sh scripts/setup.py .deploy.json; do
    [[ -f "${DOTFILES_DIR}/${file}" ]] ||
        die "Checkout is missing ${file}. Update it to the clone-and-symlink version before applying dotfiles."
done

# Do not switch initialized submodules away from the user's selected commits.
# A recursive clone handles new installs; existing checkouts must be ready first.
SUBMODULE_STATUS="$(as_user git -C "${DOTFILES_DIR}" submodule status --recursive)"
if printf '%s\n' "${SUBMODULE_STATUS}" | grep -q '^-'; then
    die "Uninitialized submodules. As ${ADMIN_USER}, run: git -C \"${DOTFILES_DIR}\" submodule update --init --recursive"
fi

as_user bash "${DOTFILES_DIR}/setup.sh" --backup
log "Dotfiles installed; legacy ~/.cfg was left untouched"
