#!/usr/bin/env bash

set -euo pipefail

COMMAND_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../proxmox-lxc-common.sh
source "${COMMAND_DIR}/../proxmox-lxc-common.sh"

VMID=""
VERBOSE=0

usage() {
    cat <<EOF
Usage:
  proxmox-lxc status --vmid <id> [--verbose]

Required:
  --vmid <id>

Options:
  --verbose, -v    Show full setup details
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --vmid)
            VMID="$2"
            shift 2
            ;;

        --verbose|-v)
            VERBOSE=1
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

require_root

[[ -n "${VMID}" ]] ||
    die "--vmid is required."

container_exists "${VMID}" ||
    die "VMID ${VMID} does not exist."

start_container_if_needed "${VMID}"

HOSTNAME="$(
    pct exec "${VMID}" -- hostname -f 2>/dev/null ||
    printf 'unknown'
)"

ORIGIN_COMMIT="unknown"

if fetched_commit="$(origin_commit 2>/dev/null)"; then
    ORIGIN_COMMIT="${fetched_commit}"
else
    warn "Unable to fetch current origin commit; source status may be unknown."
fi

printf 'VMID %s  %s\n\n' "${VMID}" "${HOSTNAME}"

if ! pct exec "${VMID}" -- test -d "${MARKER_DIR}"; then
    printf 'No setup modules have been recorded.\n'
    exit 0
fi

mapfile -t MARKERS < <(
    pct exec "${VMID}" -- sh -c \
        "find '${MARKER_DIR}' -maxdepth 1 -type f -printf '%f\n' | sort"
)

if ((${#MARKERS[@]} == 0)); then
    printf 'No setup modules have been recorded.\n'
    exit 0
fi

if [[ "${VERBOSE}" -eq 0 ]]; then
    printf '%-22s %-10s %-10s %-10s\n' \
        "MODULE" \
        "SOURCE" \
        "ORIGIN" \
        "STATUS"

    for module in "${MARKERS[@]}"; do

        marker="$(
            pct exec "${VMID}" -- cat "${MARKER_DIR}/${module}"
        )"

        applied="$(
            printf '%s\n' "${marker}" |
                awk -F= '$1=="source_commit" {print $2}'
        )"

        relationship="$(
            commit_relationship \
                "${applied:-unknown}" \
                "${ORIGIN_COMMIT}"
        )"

        printf '%-22s %-10s %-10s %-10s\n' \
            "${module}" \
            "${applied:0:7}" \
            "${ORIGIN_COMMIT:0:7}" \
            "${relationship}"
    done

    exit 0
fi

#
# Verbose
#

if pct exec "${VMID}" -- test -f "${MANIFEST_FILE}"; then
    printf 'Bootstrap\n'
    pct exec "${VMID}" -- cat "${MANIFEST_FILE}" |
        sed 's/^/  /'
    printf '\n'
fi

printf 'Repository\n'
printf '  Origin commit: %s\n\n' "${ORIGIN_COMMIT}"

for module in "${MARKERS[@]}"; do

    marker="$(
        pct exec "${VMID}" -- cat "${MARKER_DIR}/${module}"
    )"

    applied="$(
        printf '%s\n' "${marker}" |
            awk -F= '$1=="source_commit" {print $2}'
    )"

    relationship="$(
        commit_relationship \
            "${applied:-unknown}" \
            "${ORIGIN_COMMIT}"
    )"

    printf '%s\n' "${module}"
    printf '%s\n' "${marker}" |
        sed 's/^/  /'

    printf '  origin_commit=%s\n' "${ORIGIN_COMMIT}"
    printf '  status=%s\n\n' "${relationship}"
done
