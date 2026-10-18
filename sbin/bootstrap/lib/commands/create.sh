#!/usr/bin/env bash

set -euo pipefail

COMMAND_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../proxmox-lxc-common.sh
source "${COMMAND_DIR}/../proxmox-lxc-common.sh"

VMID=""
HOSTNAME=""

CORES=1
MEMORY=512
SWAP=512
DISK=8
STORAGE="local-lvm"
BRIDGE="vmbr0"
TEMPLATE=""

ADMIN_USER="${DEFAULT_ADMIN_USER}"
SSH_PUBLIC_KEY="${DEFAULT_SSH_PUBLIC_KEY}"

SETUPS=()

usage() {
    cat <<EOF
Usage:
  proxmox-lxc create --vmid <id> --hostname <hostname> [options]

Required:
  --vmid <id>
  --hostname <hostname>

Container:
  --cores <n>          CPU cores       (default: ${CORES})
  --memory <mb>        RAM in MB       (default: ${MEMORY})
  --swap <mb>          Swap in MB      (default: ${SWAP})
  --disk <gb>          Root disk in GB (default: ${DISK})
  --storage <id>       Storage ID      (default: ${STORAGE})
  --bridge <bridge>    Network bridge  (default: ${BRIDGE})
  --template <name>    CT template     (default: newest Debian 13)

Provisioning:
  --user <user>        Admin user      (default: ${ADMIN_USER})
  --ssh-key <path>     Public SSH key  (default: ${SSH_PUBLIC_KEY})
  --setup <name>       Apply setup module; repeatable
  --git-user <name>    Git username    (default: ${GIT_SETUP_USER})
  --git-name <name>    Git real name   (default: ${GIT_SETUP_NAME})
  --git-email <email>  Git email       (default: ${GIT_SETUP_EMAIL})

Example:
  proxmox-lxc create \
      --vmid 100 \
      --hostname nut-01.darkstar.net \
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

        --hostname)
            HOSTNAME="$2"
            shift 2
            ;;

        --cores)
            CORES="$2"
            shift 2
            ;;

        --memory)
            MEMORY="$2"
            shift 2
            ;;

        --swap)
            SWAP="$2"
            shift 2
            ;;

        --disk)
            DISK="$2"
            shift 2
            ;;

        --storage)
            STORAGE="$2"
            shift 2
            ;;

        --bridge)
            BRIDGE="$2"
            shift 2
            ;;

        --template)
            TEMPLATE="$2"
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

[[ -n "${HOSTNAME}" ]] ||
    die "--hostname is required."

container_exists "${VMID}" &&
    die "VMID ${VMID} already exists."

for setup in "${SETUPS[@]}"; do
    resolve_setup_script "${setup}" >/dev/null
done

if [[ -z "${TEMPLATE}" ]]; then
    TEMPLATE="$(find_debian_template)"
fi

read -rsp "Root password for new LXC: " ROOT_PASSWORD
echo

read -rsp "Confirm root password: " ROOT_PASSWORD_CONFIRM
echo

[[ -n "${ROOT_PASSWORD}" ]] ||
    die "Root password cannot be empty."

[[ "${ROOT_PASSWORD}" == "${ROOT_PASSWORD_CONFIRM}" ]] ||
    die "Root passwords do not match."

log "Configuration"

printf '  VMID:      %s\n' "${VMID}"
printf '  Hostname:  %s\n' "${HOSTNAME}"
printf '  Template:  %s\n' "${TEMPLATE}"
printf '  CPU:       %s\n' "${CORES}"
printf '  Memory:    %s MB\n' "${MEMORY}"
printf '  Swap:      %s MB\n' "${SWAP}"
printf '  Disk:      %s GB\n' "${DISK}"
printf '  Storage:   %s\n' "${STORAGE}"
printf '  Network:   DHCP on %s\n' "${BRIDGE}"
printf '  User:      %s\n' "${ADMIN_USER}"

log "Creating LXC"

pct create "${VMID}" "${TEMPLATE}" \
    --hostname "${HOSTNAME}" \
    --cores "${CORES}" \
    --memory "${MEMORY}" \
    --swap "${SWAP}" \
    --rootfs "${STORAGE}:${DISK}" \
    --net0 "name=eth0,bridge=${BRIDGE},ip=dhcp,type=veth,firewall=1" \
    --unprivileged 1 \
    --onboot 1

pct start "${VMID}"
wait_for_network "${VMID}"

push_baseline_files \
    "${VMID}" \
    "${SSH_PUBLIC_KEY}"

run_debian_baseline \
    "${VMID}" \
    "${ADMIN_USER}" \
    "${ROOT_PASSWORD}"

unset ROOT_PASSWORD ROOT_PASSWORD_CONFIRM

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
