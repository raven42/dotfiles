#!/usr/bin/env bash

set -euo pipefail

LIB_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BOOTSTRAP_DIR="$(cd -- "${LIB_DIR}/.." && pwd)"

SETUP_DIR="${BOOTSTRAP_DIR}/setup"
SERVICE_SETUP_DIR="${SETUP_DIR}/services"
DEBIAN_BOOTSTRAP="${LIB_DIR}/debian.sh"

STATE_DIR="/var/lib/darkstar-bootstrap"
MARKER_DIR="${STATE_DIR}/setups"
MANIFEST_FILE="${STATE_DIR}/manifest"

DEFAULT_ADMIN_USER="raven"
DEFAULT_SSH_PUBLIC_KEY="/opt/darkstar/keys/raven_ed25519.pub"

log() {
    printf '\n\033[1;34m==>\033[0m %s\n' "$*"
}

warn() {
    printf '\n\033[1;33mWARNING:\033[0m %s\n' "$*" >&2
}

die() {
    printf '\n\033[1;31mERROR:\033[0m %s\n' "$*" >&2
    exit 1
}

require_root() {
    [[ "${EUID}" -eq 0 ]] ||
        die "This command must be run as root on a Proxmox host."
}

container_exists() {
    local vmid="$1"
    pct status "${vmid}" &>/dev/null
}

container_running() {
    local vmid="$1"

    pct status "${vmid}" 2>/dev/null |
        grep -q '^status: running$'
}

wait_for_network() {
    local vmid="$1"
    local attempts="${2:-30}"
    local i

    log "Waiting for container networking"

    for ((i = 1; i <= attempts; i++)); do
        if pct exec "${vmid}" -- \
            sh -c 'ip -4 route | grep -q "^default "' 2>/dev/null; then
            return 0
        fi

        sleep 2
    done

    die "Container ${vmid} did not obtain a default route within $((attempts * 2)) seconds."
}

start_container_if_needed() {
    local vmid="$1"

    if container_running "${vmid}"; then
        return
    fi

    log "Starting LXC ${vmid}"
    pct start "${vmid}"
    wait_for_network "${vmid}"
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

list_setup_names() {
    local file

    if [[ -d "${SETUP_DIR}" ]]; then
        for file in "${SETUP_DIR}"/*.sh; do
            [[ -f "${file}" ]] || continue
            basename "${file}" .sh
        done
    fi

    if [[ -d "${SERVICE_SETUP_DIR}" ]]; then
        for file in "${SERVICE_SETUP_DIR}"/*.sh; do
            [[ -f "${file}" ]] || continue
            basename "${file}" .sh
        done
    fi
}

resolve_setup_script() {
    local name="$1"
    local candidate

    [[ "${name}" =~ ^[A-Za-z0-9._-]+$ ]] ||
        die "Invalid setup module name: ${name}"

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

repo_root() {
    git \
        -c safe.directory='*' \
        -C "${BOOTSTRAP_DIR}" \
        rev-parse --show-toplevel 2>/dev/null
}

source_commit() {
    local root

    root="$(repo_root 2>/dev/null)" || {
        printf 'unknown\n'
        return
    }

    git \
        -c safe.directory="${root}" \
        -C "${root}" \
        rev-parse HEAD 2>/dev/null ||
        printf 'unknown\n'
}

origin_commit() {
    local root
    local branch
    local ref

    root="$(repo_root 2>/dev/null)" || return 1

    git \
        -c safe.directory="${root}" \
        -C "${root}" \
        fetch --quiet origin || return 1

    branch="$(
        git \
            -c safe.directory="${root}" \
            -C "${root}" \
            branch --show-current
    )"

    if [[ -n "${branch}" ]] &&
       git -c safe.directory="${root}" -C "${root}" \
           rev-parse --verify "origin/${branch}" &>/dev/null; then

        ref="origin/${branch}"

    elif git -c safe.directory="${root}" -C "${root}" \
         rev-parse --verify origin/HEAD &>/dev/null; then

        ref="origin/HEAD"

    else
        return 1
    fi

    git \
        -c safe.directory="${root}" \
        -C "${root}" \
        rev-parse "${ref}"
}

commit_relationship() {
    local applied="$1"
    local origin="$2"
    local root

    if [[ -z "${applied}" || "${applied}" == "unknown" ]]; then
        printf 'unknown\n'
        return
    fi

    if [[ -z "${origin}" || "${origin}" == "unknown" ]]; then
        printf 'unknown\n'
        return
    fi

    # Supports both current full hashes and older short-hash markers.
    if [[ "${origin}" == "${applied}"* || "${applied}" == "${origin}"* ]]; then
        printf 'current\n'
        return
    fi

    root="$(repo_root 2>/dev/null)" || {
        printf 'unknown\n'
        return
    }

    if git -c safe.directory="${root}" -C "${root}" \
        merge-base --is-ancestor "${applied}" "${origin}" 2>/dev/null; then

        printf 'behind\n'

    elif git -c safe.directory="${root}" -C "${root}" \
        merge-base --is-ancestor "${origin}" "${applied}" 2>/dev/null; then

        printf 'ahead\n'

    else
        printf 'diverged\n'
    fi
}

push_baseline_files() {
    local vmid="$1"
    local ssh_key="$2"

    [[ -f "${DEBIAN_BOOTSTRAP}" ]] ||
        die "Debian bootstrap not found: ${DEBIAN_BOOTSTRAP}"

    [[ -f "${ssh_key}" ]] ||
        die "SSH public key not found: ${ssh_key}"

    log "Copying SSH public key"

    pct push \
        "${vmid}" \
        "${ssh_key}" \
        /root/ssh_key.pub \
        --perms 0600

    log "Copying Debian bootstrap"

    pct push \
        "${vmid}" \
        "${DEBIAN_BOOTSTRAP}" \
        /root/debian-bootstrap.sh \
        --perms 0755
}

run_debian_baseline() {
    local vmid="$1"
    local admin_user="$2"
    local root_password="${3:-}"

    log "Running Debian baseline"

    if [[ -n "${root_password}" ]]; then
        pct exec "${vmid}" -- \
            env \
                ADMIN_USER="${admin_user}" \
                ROOT_PASSWORD="${root_password}" \
            /root/debian-bootstrap.sh
    else
        pct exec "${vmid}" -- \
            env \
                ADMIN_USER="${admin_user}" \
            /root/debian-bootstrap.sh
    fi
}

ensure_state_manifest() {
    local vmid="$1"

    pct exec "${vmid}" -- mkdir -p "${MARKER_DIR}"

    if ! pct exec "${vmid}" -- test -f "${MANIFEST_FILE}"; then
        pct exec "${vmid}" -- sh -c "
            cat > '${MANIFEST_FILE}' <<EOF
version=1
created_at=\$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF
        "
    fi
}

record_setup_marker() {
    local vmid="$1"
    local setup="$2"
    local commit="$3"

    ensure_state_manifest "${vmid}"

    pct exec "${vmid}" -- sh -c "
        cat > '${MARKER_DIR}/${setup}' <<EOF
module=${setup}
applied_at=\$(date -u +%Y-%m-%dT%H:%M:%SZ)
source_commit=${commit}
EOF
    "
}

run_setup_module() {
    local vmid="$1"
    local admin_user="$2"
    local setup="$3"
    local setup_script
    local remote_script
    local commit

    setup_script="$(resolve_setup_script "${setup}")"
    remote_script="/root/setup-${setup}.sh"
    commit="$(source_commit)"

    log "Copying setup module: ${setup}"

    pct push \
        "${vmid}" \
        "${setup_script}" \
        "${remote_script}" \
        --perms 0755

    log "Running setup module: ${setup}"

    pct exec "${vmid}" -- \
        env ADMIN_USER="${admin_user}" \
        "${remote_script}"

    record_setup_marker \
        "${vmid}" \
        "${setup}" \
        "${commit}"

    pct exec "${vmid}" -- rm -f "${remote_script}"
}

cleanup_baseline_files() {
    local vmid="$1"

    pct exec "${vmid}" -- rm -f \
        /root/debian-bootstrap.sh \
        /root/ssh_key.pub
}

show_container_summary() {
    local vmid="$1"

    pct exec "${vmid}" -- sh -c '
        printf "Hostname: "
        hostname -f 2>/dev/null || hostname

        printf "Address:  "
        hostname -I | awk "{print \$1}"
    '
}
