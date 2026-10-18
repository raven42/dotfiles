#!/usr/bin/env bash

set -euo pipefail

COMMAND_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../proxmox-lxc-common.sh
source "${COMMAND_DIR}/../proxmox-lxc-common.sh"

VMID=""
ADMIN_USER="${DEFAULT_ADMIN_USER}"
SSH_PUBLIC_KEY="${DEFAULT_SSH_PUBLIC_KEY}"

SETUPS=()

usage() {
    cat <<EOF
Usage:
  proxmox-lxc apply --vmid <id> [options]

Required:
  --vmid <id>

Options:
  --user <user>       Admin user     (default: ${ADMIN_USER})
  --ssh-key <path>    Public SSH key (default: ${SSH_PUBLIC_KEY})
  --setup <name>      Apply setup module; repeatable
  --git-user <name>   Git username    (default: ${GIT_SETUP_USER})
  --git-name <name>   Git real name   (default: ${GIT_SETUP_NAME})
  --git-email <mail>  Git email       (default: ${GIT_SETUP_EMAIL})

Examples:
  proxmox-lxc apply --vmid 100 --setup nut

  proxmox-lxc apply \
      --vmid 100 \
      --setup dotfiles \
      --setup ansible-managed \
      --setup nut
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --vmid)
            VMID="$2"
            shift 2
            ;;

        --user)
            ADMIN_USER="$2"
            shift 2
            ;;

        --ssh-key)
            SSH_PUBLIC_KEY="$2"
            shift 2
            ;;

        --git-user|--git-name|--git-email)
            [[ $# -ge 2 && -n "$2" && "$2" != -* ]] ||
                die "$1 requires a value."
            case "$1" in
                --git-user) GIT_SETUP_USER="$2" ;;
                --git-name) GIT_SETUP_NAME="$2" ;;
                --git-email) GIT_SETUP_EMAIL="$2" ;;
            esac
            shift 2
            ;;

        --setup)
            SETUPS+=("$2")
            shift 2
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

require_root

[[ -n "${VMID}" ]] ||
    die "--vmid is required."

container_exists "${VMID}" ||
    die "VMID ${VMID} does not exist."

for setup in "${SETUPS[@]}"; do
    resolve_setup_script "${setup}" >/dev/null
done

start_container_if_needed "${VMID}"

push_baseline_files \
    "${VMID}" \
    "${SSH_PUBLIC_KEY}"

run_debian_baseline \
    "${VMID}" \
    "${ADMIN_USER}"

ensure_state_manifest "${VMID}"

for setup in "${SETUPS[@]}"; do
    run_setup_module \
        "${VMID}" \
        "${ADMIN_USER}" \
        "${setup}"
done

cleanup_baseline_files "${VMID}"

log "Provisioning complete"
show_container_summary "${VMID}"
