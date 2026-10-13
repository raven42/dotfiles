#!/usr/bin/env bash

_proxmox_lxc_setup_modules() {
    local bootstrap_dir setup_dir service_dir file

    bootstrap_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
    setup_dir="${bootstrap_dir}/setup"
    service_dir="${setup_dir}/services"

    if [[ -d "${setup_dir}" ]]; then
        for file in "${setup_dir}"/*.sh; do
            [[ -f "${file}" ]] || continue
            basename "${file}" .sh
        done
    fi

    if [[ -d "${service_dir}" ]]; then
        for file in "${service_dir}"/*.sh; do
            [[ -f "${file}" ]] || continue
            basename "${file}" .sh
        done
    fi
}

_proxmox_lxc_vmids() {
    pct list 2>/dev/null |
        awk 'NR > 1 {print $1}'
}

_proxmox_lxc() {
    local cur prev command
    local commands="create apply list status help"

    COMPREPLY=()

    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"
    command="${COMP_WORDS[1]:-}"

    # First argument: subcommand
    if [[ "${COMP_CWORD}" -eq 1 ]]; then
        COMPREPLY=(
            $(compgen -W "${commands}" -- "${cur}")
        )
        return
    fi

    # Value completion
    case "${prev}" in
        --vmid)
            COMPREPLY=(
                $(compgen -W "$(_proxmox_lxc_vmids)" -- "${cur}")
            )
            return
            ;;

        --setup)
            COMPREPLY=(
                $(compgen -W "$(_proxmox_lxc_setup_modules | sort -u)" -- "${cur}")
            )
            return
            ;;

        --storage)
            COMPREPLY=(
                $(compgen -W "$(pvesm status 2>/dev/null | awk 'NR > 1 {print $1}')" -- "${cur}")
            )
            return
            ;;

        --bridge)
            COMPREPLY=(
                $(compgen -W "$(ip -o link show 2>/dev/null | awk -F': ' '{print $2}' | grep '^vmbr')" -- "${cur}")
            )
            return
            ;;

        --template)
            COMPREPLY=(
                $(compgen -W "$(pveam list local 2>/dev/null | awk 'NR > 1 {print $1}')" -- "${cur}")
            )
            return
            ;;
    esac

    case "${command}" in
        create)
            COMPREPLY=(
                $(compgen -W "
                    --vmid
                    --hostname
                    --cores
                    --memory
                    --swap
                    --disk
                    --storage
                    --bridge
                    --template
                    --user
                    --ssh-key
                    --setup
                    --help
                " -- "${cur}")
            )
            ;;

        apply)
            COMPREPLY=(
                $(compgen -W "
                    --vmid
                    --user
                    --ssh-key
                    --setup
                    --help
                " -- "${cur}")
            )
            ;;

        list)
            COMPREPLY=(
                $(compgen -W "
                    --verbose
                    -v
                    --help
                " -- "${cur}")
            )
            ;;

        status)
            COMPREPLY=(
                $(compgen -W "
                    --vmid
                    --verbose
                    -v
                    --help
                " -- "${cur}")
            )
            ;;
    esac
}

complete -F _proxmox_lxc proxmox-lxc
