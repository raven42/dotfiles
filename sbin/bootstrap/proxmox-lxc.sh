#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Create and bootstrap a Debian LXC on Proxmox.
#
# Usage:
#   ./proxmox-lxc.sh --vmid 101 --hostname nginx-01.darkstar.net
#
# Optional:
#   --cores 2
#   --memory 1024
#   --swap 512
#   --disk 8
#   --storage local-lvm
#   --bridge vmbr0
#   --template local:vztmpl/debian-13-standard_13.6-1_amd64.tar.zst
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEBIAN_BOOTSTRAP="${SCRIPT_DIR}/debian.sh"

VMID=""
HOSTNAME=""

CORES=1
MEMORY=512
SWAP=512
DISK=8
STORAGE="local-lvm"
BRIDGE="vmbr0"
TEMPLATE=""

SSH_PUBLIC_KEY="/opt/darkstar/keys/raven_ed25519.pub"

log() {
    printf '\n\033[1;34m==>\033[0m %s\n' "$*"
}

die() {
    printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<EOF
Usage:
  $(basename "$0") --vmid <id> --hostname <hostname> [options]

Required:
  --vmid       Proxmox VMID
  --hostname   LXC hostname/FQDN

Options:
  --cores      CPU cores       (default: ${CORES})
  --memory     RAM in MB       (default: ${MEMORY})
  --swap       Swap in MB      (default: ${SWAP})
  --disk       Root disk in GB (default: ${DISK})
  --storage    Storage ID      (default: ${STORAGE})
  --bridge     Network bridge  (default: ${BRIDGE})
  --template   CT template     (default: newest local Debian 13 template)
  -h, --help   Show this help
EOF
}

require_root() {
    [[ "${EUID}" -eq 0 ]] ||
        die "This script must be run as root on a Proxmox host."
}

find_debian_template() {
    local template

    template="$(
        pveam list local 2>/dev/null |
        awk 'NR > 1 {print $1}' |
        grep -E '^local:vztmpl/debian-13-standard_.*_amd64\.tar\.zst$' |
        sort -V |
        tail -1
    )"

    [[ -n "${template}" ]] ||
        die "No local Debian 13 LXC template was found."

    printf '%s\n' "${template}"
}

wait_for_network() {
    local attempts=30

    log "Waiting for container networking"

    for ((i = 1; i <= attempts; i++)); do
        if pct exec "${VMID}" -- \
            sh -c 'ip -4 route | grep -q "^default "' 2>/dev/null; then
            return 0
        fi

        sleep 2
    done

    die "Container did not obtain a default route within $((attempts * 2)) seconds."
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

[[ -n "${VMID}" ]] || die "--vmid is required."
[[ -n "${HOSTNAME}" ]] || die "--hostname is required."
[[ -f "${DEBIAN_BOOTSTRAP}" ]] ||
    die "Debian bootstrap not found: ${DEBIAN_BOOTSTRAP}"

if pct status "${VMID}" &>/dev/null; then
    die "VMID ${VMID} already exists."
fi

if [[ -z "${TEMPLATE}" ]]; then
    TEMPLATE="$(find_debian_template)"
fi

log "Configuration"
printf '  VMID:      %s\n' "${VMID}"
printf '  Hostname:  %s\n' "${HOSTNAME}"
printf '  Template:  %s\n' "${TEMPLATE}"
printf '  CPU:       %s core(s)\n' "${CORES}"
printf '  Memory:    %s MB\n' "${MEMORY}"
printf '  Swap:      %s MB\n' "${SWAP}"
printf '  Disk:      %s GB\n' "${DISK}"
printf '  Storage:   %s\n' "${STORAGE}"
printf '  Network:   DHCP on %s\n' "${BRIDGE}"

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

log "Starting LXC"
pct start "${VMID}"

wait_for_network

log "Copying SSH public key"

[[ -f "${SSH_PUBLIC_KEY}" ]] ||
    die "SSH public key not found: ${SSH_PUBLIC_KEY}"

pct push \
    "${VMID}" \
    "${SSH_PUBLIC_KEY}" \
    /root/raven_ed25519.pub \
    --perms 0600

log "Copying Debian bootstrap"
pct push \
    "${VMID}" \
    "${DEBIAN_BOOTSTRAP}" \
    /root/debian-bootstrap.sh \
    --perms 0755

log "Running Debian bootstrap"
pct exec "${VMID}" -- /root/debian-bootstrap.sh

log "Removing temporary bootstrap"
pct exec "${VMID}" -- rm -f \
    /root/debian-bootstrap.sh \
    /root/raven_ed25519.pub

log "Provisioning complete"

pct exec "${VMID}" -- sh -c '
    printf "Hostname: "
    hostname -f 2>/dev/null || hostname

    printf "Address:  "
    hostname -I | awk "{print \$1}"
'