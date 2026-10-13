#!/usr/bin/env bash

set -euo pipefail

COMMAND_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=../proxmox-lxc-common.sh
source "${COMMAND_DIR}/../proxmox-lxc-common.sh"

VERBOSE=0

usage() {
    cat <<EOF
Usage:
  proxmox-lxc list [--verbose]

Options:
  --verbose     Show source path for each setup module
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
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

printf 'Available setup modules:\n\n'

while IFS= read -r setup; do
    [[ -n "${setup}" ]] || continue

    if [[ "${VERBOSE}" -eq 1 ]]; then
        printf '  %-24s %s\n' \
            "${setup}" \
            "$(resolve_setup_script "${setup}")"
    else
        printf '  %s\n' "${setup}"
    fi

done < <(list_setup_names | sort -u)
