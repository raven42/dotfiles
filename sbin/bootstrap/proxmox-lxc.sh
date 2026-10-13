#!/usr/bin/env bash

set -euo pipefail

# -----------------------------------------------------------------------------
# Create and/or provision a Debian LXC on Proxmox.
#
# Examples:
#
#   List available setup modules:
#     ./proxmox-lxc.sh --list
#
#   Show applied setup modules:
#     ./proxmox-lxc.sh --vmid 100 --status
#
#   Create a new LXC:
#     ./proxmox-lxc.sh \
#         --vmid 100 \
#         --create \
#         --hostname nut-01.darkstar.net \
#         --setup dotfiles \
#         --setup ansible-managed \
#         --setup nut
#
#   Update an existing LXC:
#     ./proxmox-lxc.sh \
#         --vmid 100 \
#         --setup nut
# -----------------------------------------------------------------------------

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

DEBIAN_BOOTSTRAP="${SCRIPT_DIR}/debian.sh"
SETUP_DIR="${SCRIPT_DIR}/setup"
SERVICE_SETUP_DIR="${SETUP_DIR}/services"

MARKER_DIR="/var/lib/darkstar-bootstrap/setups"

VMID=""
HOSTNAME=""
CREATE=0
SHOW_LIST=0
SHOW_STATUS=0

CORES=1
MEMORY=512
SWAP=512
DISK=8
STORAGE="local-lvm"
BRIDGE="vmbr0"
TEMPLATE=""

ADMIN_USER="raven"
SSH_PUBLIC_KEY="/opt/darkstar/keys/raven_ed25519.pub"

SETUPS=()
SETUP_SCRIPTS=()
CREATE_ONLY_OPTIONS=()

ROOT_PASSWORD=""
ROOT_PASSWORD_CONFIRM=""

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
  $(basename "$0") [options]

General:
  --list                 List available setup modules
  --status               Show setup modules applied to an LXC
  --vmid <id>            Proxmox VMID
  -h, --help             Show this help

Create:
  --create               Create a new LXC before provisioning
  --hostname <hostname>  LXC hostname/FQDN (required with --create)

Create-only options:
  --cores <n>            CPU cores       (default: ${CORES})
  --memory <mb>          RAM in MB       (default: ${MEMORY})
  --swap <mb>            Swap in MB      (default: ${SWAP})
  --disk <gb>            Root disk in GB (default: ${DISK})
  --storage <id>         Storage ID      (default: ${STORAGE})
  --bridge <bridge>      Network bridge  (default: ${BRIDGE})
  --template <template>  CT template     (default: newest local Debian 13)

Provisioning:
  --user <user>          Admin user      (default: ${ADMIN_USER})
  --ssh-key <path>       Public SSH key  (default: ${SSH_PUBLIC_KEY})
  --setup <name>         Apply setup module; repeatable

Examples:

  $(basename "$0") --list

  $(basename "$0") \
      --vmid 100 \
      --status

  $(basename "$0") \
      --vmid 100 \
      --create \
      --hostname nut-01.darkstar.net \
      --setup dotfiles \
      --setup ansible-managed \
      --setup nut

  $(basename "$0") \
      --vmid 100 \
      --setup nut
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

source_commit() {
    git -C "${SCRIPT_DIR}" rev-parse --short HEAD 2>/dev/null ||
        printf 'unknown\n'
}

list_setup_modules() {
    local found=0
    local file

    printf 'Available setup modules:\n\n'

    if [[ -d "${SETUP_DIR}" ]]; then
        for file in "${SETUP_DIR}"/*.sh; do
            [[ -f "${file}" ]] || continue
            printf '  %-24s %s\n' \
                "$(basename "${file}" .sh)" \
                "setup/$(basename "${file}")"
            found=1
        done
    fi

    if [[ -d "${SERVICE_SETUP_DIR}" ]]; then
        for file in "${SERVICE_SETUP_DIR}"/*.sh; do
            [[ -f "${file}" ]] || continue
            printf '  %-24s %s\n' \
                "$(basename "${file}" .sh)" \
                "setup/services/$(basename "${file}")"
            found=1
        done
    fi

    [[ "${found}" -eq 1 ]] ||
        printf '  No setup modules found.\n'
}

resolve_setup_script() {
    local name="$1"
    local candidate

    [[ "${name}" =~ ^[A-Za-z0-9._-]+$ ]] ||
        die "Invalid setup name: ${name}"

    candidate="${SETUP_DIR}/${name}.sh"

    if [[ -f "${candidate}" ]]; then
        printf '%s\n' "${candidate}"
        return
    fi

    candidate="${SERVICE_SETUP_DIR}/${name}.sh"

    if [[ -f "${candidate}" ]]; then
        printf '%s\n' "${candidate}"
        return
    fi

    die "Setup module not found: ${name}"
}

container_exists() {
    pct status "${VMID}" &>/dev/null
}

container_running() {
    pct status "${VMID}" 2>/dev/null |
        grep -q '^status: running$'
}

wait_for_network() {
    local attempts=30
    local i

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

start_container_if_needed() {
    if container_running; then
        return
    fi

    log "Starting LXC ${VMID}"
    pct start "${VMID}"
    wait_for_network
}

show_status() {
    container_exists ||
        die "VMID ${VMID} does not exist."

    container_running ||
        die "VMID ${VMID} must be running to display setup status."

    printf '\nApplied setup modules for VMID %s:\n\n' "${VMID}"

    pct exec "${VMID}" -- sh -c "
        if [ ! -d '${MARKER_DIR}' ]; then
            echo '  None'
            exit 0
        fi

        found=0

        for marker in '${MARKER_DIR}'/*; do
            [ -f \"\$marker\" ] || continue

            found=1

            printf '%s\n' '----------------------------------------'
            printf 'Module: %s\n' \"\$(basename \"\$marker\")\"
            cat \"\$marker\"
        done

        if [ \"\$found\" -eq 0 ]; then
            echo '  None'
        fi
    "

    printf '\n'
}

prompt_root_password() {
    read -rsp "Root password for new LXC: " ROOT_PASSWORD
    echo

    read -rsp "Confirm root password: " ROOT_PASSWORD_CONFIRM
    echo

    [[ "${ROOT_PASSWORD}" == "${ROOT_PASSWORD_CONFIRM}" ]] ||
        die "Root passwords do not match."

    [[ -n "${ROOT_PASSWORD}" ]] ||
        die "Root password cannot be empty."
}

create_container() {
    if [[ -z "${TEMPLATE}" ]]; then
        TEMPLATE="$(find_debian_template)"
    fi

    prompt_root_password

    log "Configuration"

    printf '  Mode:      create\n'
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
}

push_common_bootstrap() {
    log "Copying SSH public key"

    pct push \
        "${VMID}" \
        "${SSH_PUBLIC_KEY}" \
        /root/ssh_key.pub \
        --perms 0600

    log "Copying Debian bootstrap"

    pct push \
        "${VMID}" \
        "${DEBIAN_BOOTSTRAP}" \
        /root/debian-bootstrap.sh \
        --perms 0755
}

run_debian_bootstrap() {
    log "Running Debian bootstrap"

    if [[ -n "${ROOT_PASSWORD}" ]]; then
        pct exec "${VMID}" -- \
            env \
                ROOT_PASSWORD="${ROOT_PASSWORD}" \
                ADMIN_USER="${ADMIN_USER}" \
            /root/debian-bootstrap.sh
    else
        pct exec "${VMID}" -- \
            env \
                ADMIN_USER="${ADMIN_USER}" \
            /root/debian-bootstrap.sh
    fi

    unset ROOT_PASSWORD ROOT_PASSWORD_CONFIRM
}

record_setup_marker() {
    local setup="$1"
    local commit="$2"

    pct exec "${VMID}" -- \
        mkdir -p "${MARKER_DIR}"

    pct exec "${VMID}" -- \
        sh -c "cat > '${MARKER_DIR}/${setup}' <<EOF
applied_at=\$(date -u +%Y-%m-%dT%H:%M:%SZ)
source_commit=${commit}
module=${setup}
EOF"
}

run_setup_modules() {
    local i
    local setup
    local setup_script
    local remote_script
    local commit

    commit="$(source_commit)"

    for i in "${!SETUPS[@]}"; do
        setup="${SETUPS[$i]}"
        setup_script="${SETUP_SCRIPTS[$i]}"
        remote_script="/root/setup-${setup}.sh"

        log "Copying setup module: ${setup}"

        pct push \
            "${VMID}" \
            "${setup_script}" \
            "${remote_script}" \
            --perms 0755

        log "Running setup module: ${setup}"

        pct exec "${VMID}" -- \
            env ADMIN_USER="${ADMIN_USER}" \
            "${remote_script}"

        #
        # We only reach this point when the setup script exits successfully.
        #
        record_setup_marker "${setup}" "${commit}"
    done
}

cleanup_bootstrap_files() {
    log "Removing temporary bootstrap files"

    pct exec "${VMID}" -- rm -f \
        /root/debian-bootstrap.sh \
        /root/ssh_key.pub

    for setup in "${SETUPS[@]}"; do
        pct exec "${VMID}" -- \
            rm -f "/root/setup-${setup}.sh"
    done
}

show_summary() {
    log "Provisioning complete"

    pct exec "${VMID}" -- sh -c '
        printf "Hostname: "
        hostname -f 2>/dev/null || hostname

        printf "Address:  "
        hostname -I | awk "{print \$1}"
    '

    if ((${#SETUPS[@]} > 0)); then
        printf '\nApplied setup modules:\n'

        for setup in "${SETUPS[@]}"; do
            printf '  %s\n' "${setup}"
        done
    fi
}

#
# Parse command line
#

while [[ $# -gt 0 ]]; do
    case "$1" in
        --list)
            SHOW_LIST=1
            shift
            ;;

        --status)
            SHOW_STATUS=1
            shift
            ;;

        --vmid)
            [[ $# -ge 2 ]] || die "--vmid requires a value."
            VMID="$2"
            shift 2
            ;;

        --create)
            CREATE=1
            shift
            ;;

        --hostname)
            [[ $# -ge 2 ]] || die "--hostname requires a value."
            HOSTNAME="$2"
            CREATE_ONLY_OPTIONS+=("--hostname")
            shift 2
            ;;

        --user)
            [[ $# -ge 2 ]] || die "--user requires a value."
            ADMIN_USER="$2"
            shift 2
            ;;

        --ssh-key)
            [[ $# -ge 2 ]] || die "--ssh-key requires a value."
            SSH_PUBLIC_KEY="$2"
            shift 2
            ;;

        --cores)
            [[ $# -ge 2 ]] || die "--cores requires a value."
            CORES="$2"
            CREATE_ONLY_OPTIONS+=("--cores")
            shift 2
            ;;

        --memory)
            [[ $# -ge 2 ]] || die "--memory requires a value."
            MEMORY="$2"
            CREATE_ONLY_OPTIONS+=("--memory")
            shift 2
            ;;

        --swap)
            [[ $# -ge 2 ]] || die "--swap requires a value."
            SWAP="$2"
            CREATE_ONLY_OPTIONS+=("--swap")
            shift 2
            ;;

        --disk)
            [[ $# -ge 2 ]] || die "--disk requires a value."
            DISK="$2"
            CREATE_ONLY_OPTIONS+=("--disk")
            shift 2
            ;;

        --storage)
            [[ $# -ge 2 ]] || die "--storage requires a value."
            STORAGE="$2"
            CREATE_ONLY_OPTIONS+=("--storage")
            shift 2
            ;;

        --bridge)
            [[ $# -ge 2 ]] || die "--bridge requires a value."
            BRIDGE="$2"
            CREATE_ONLY_OPTIONS+=("--bridge")
            shift 2
            ;;

        --template)
            [[ $# -ge 2 ]] || die "--template requires a value."
            TEMPLATE="$2"
            CREATE_ONLY_OPTIONS+=("--template")
            shift 2
            ;;

        --setup)
            [[ $# -ge 2 ]] || die "--setup requires a value."
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

#
# Standalone informational commands
#

if [[ "${SHOW_LIST}" -eq 1 ]]; then
    list_setup_modules
    exit 0
fi

require_root

if [[ "${SHOW_STATUS}" -eq 1 ]]; then
    [[ -n "${VMID}" ]] ||
        die "--vmid is required with --status."

    show_status
    exit 0
fi

#
# Validate provisioning request
#

[[ -n "${VMID}" ]] ||
    die "--vmid is required."

[[ -f "${DEBIAN_BOOTSTRAP}" ]] ||
    die "Debian bootstrap not found: ${DEBIAN_BOOTSTRAP}"

[[ -f "${SSH_PUBLIC_KEY}" ]] ||
    die "SSH public key not found: ${SSH_PUBLIC_KEY}"

for setup in "${SETUPS[@]}"; do
    SETUP_SCRIPTS+=("$(resolve_setup_script "${setup}")")
done

if [[ "${CREATE}" -eq 1 ]]; then

    container_exists &&
        die "VMID ${VMID} already exists."

    [[ -n "${HOSTNAME}" ]] ||
        die "--hostname is required with --create."

else

    container_exists ||
        die "VMID ${VMID} does not exist. Use --create to create it."

    if ((${#CREATE_ONLY_OPTIONS[@]} > 0)); then
        die "Create-only option(s) used without --create: ${CREATE_ONLY_OPTIONS[*]}"
    fi
fi

#
# Create or start target
#

if [[ "${CREATE}" -eq 1 ]]; then
    create_container
else
    log "Configuration"
    printf '  Mode:      update\n'
    printf '  VMID:      %s\n' "${VMID}"

    start_container_if_needed
fi

#
# Apply provisioning
#

push_common_bootstrap
run_debian_bootstrap
run_setup_modules
cleanup_bootstrap_files
show_summary
