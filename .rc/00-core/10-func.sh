# Event callbacks use indexed arrays for Bash 3.2 compatibility. Keep registrations
# when these helpers are re-sourced; rc_on ignores duplicate event/function pairs.
rc_on() {
    local rc_event_name=${1:-} rc_callback_name=${2:-} rc_entry
    if [[ $# != 2 || ! $rc_event_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ||
          ! $rc_callback_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        printf 'Usage: rc_on event function\n' >&2
        return 2
    fi
    if ! declare -F "$rc_callback_name" >/dev/null; then
        printf 'rc_on: function not defined: %s\n' "$rc_callback_name" >&2
        return 1
    fi
    for rc_entry in "${__RC_CALLBACKS[@]}"; do
        [[ $rc_entry != "$rc_event_name:$rc_callback_name" ]] || return 0
    done
    __RC_CALLBACKS+=("$rc_event_name:$rc_callback_name")
}

rc_off() {
    local rc_event_name=${1:-} rc_callback_name=${2:-} rc_entry
    local -a rc_remaining=()
    if [[ $# != 2 ]]; then
        printf 'Usage: rc_off event function\n' >&2
        return 2
    fi
    for rc_entry in "${__RC_CALLBACKS[@]}"; do
        [[ $rc_entry == "$rc_event_name:$rc_callback_name" ]] ||
            rc_remaining+=("$rc_entry")
    done
    __RC_CALLBACKS=("${rc_remaining[@]}")
}

# Snapshot registrations: callback changes take effect on the next emission.
# Run in the current shell so callbacks can update its environment. A failing
# callback is reported, but does not prevent the remaining callbacks from running.
rc_emit() {
    local rc_event_name=${1:-} rc_entry rc_callback_name rc_status=0
    local -a rc_snapshot=("${__RC_CALLBACKS[@]}")
    if [[ $# == 0 ]]; then
        printf 'Usage: rc_emit event [arguments ...]\n' >&2
        return 2
    fi
    shift
    for rc_entry in "${rc_snapshot[@]}"; do
        [[ ${rc_entry%%:*} == "$rc_event_name" ]] || continue
        rc_callback_name=${rc_entry#*:}
        if ! declare -F "$rc_callback_name" >/dev/null; then
            printf 'rc_emit %s: missing function %s\n' \
                "$rc_event_name" "$rc_callback_name" >&2
            rc_status=1
        elif "$rc_callback_name" "$@"; then
            :
        else
            printf 'rc_emit %s: %s returned %s\n' \
                "$rc_event_name" "$rc_callback_name" "$?" >&2
            rc_status=1
        fi
    done
    return "$rc_status"
}

# Shared helpers. No environment mutation until a caller invokes them.
path_append() {
    local variable=$1 value=$2 current_value=${!1}
    [[ -d $value ]] || return 0
    case ":$current_value:" in *":$value:"*) return 0 ;; esac
    printf -v "$variable" '%s' "${current_value:+$current_value:}$value"
}
path_prepend() {
    local variable=$1 value=$2 current_value=${!1}
    [[ -d $value ]] || return 0
    case ":$current_value:" in *":$value:"*) return 0 ;; esac
    printf -v "$variable" '%s' "$value${current_value:+:$current_value}"
}
path_remove() {
    local variable=$1 value=$2 remaining=${!1} part result= separator=
    while :; do
        part=${remaining%%:*}
        if [[ $part != "$value" ]]; then
            result="$result$separator$part"
            separator=:
        fi
        [[ $remaining == *:* ]] || break
        remaining=${remaining#*:}
    done
    printf -v "$variable" '%s' "$result"
}

# Only deactivate environments owned by this helper; manual activation wins.
# The marker is shell-local, so inherited/manual environments are not claimed.
rc_update_venv() {
    local directory=$PWD candidate= preserved_path=
    if [[ -n ${__RC_AUTO_VENV:-} && ${VIRTUAL_ENV:-} != "$__RC_AUTO_VENV" ]]; then
        unset __RC_AUTO_VENV __RC_AUTO_VENV_CANDIDATE
    fi
    [[ -n ${VIRTUAL_ENV:-} && -z ${__RC_AUTO_VENV:-} ]] && return 0
    if [[ ${RC_AUTO_VENV:-1} == 1 ]]; then
        while :; do
            if [[ -r $directory/.venv/bin/activate ]]; then
                candidate="$directory/.venv"
                break
            fi
            [[ $directory == / ]] && break
            directory=${directory%/*}
            [[ -n $directory ]] || directory=/
        done
    fi
    [[ $candidate == "${__RC_AUTO_VENV_CANDIDATE:-}" ]] && return 0
    if [[ -n ${__RC_AUTO_VENV:-} ]]; then
        path_remove PATH "$__RC_AUTO_VENV/bin"
        preserved_path=$PATH
        if declare -F deactivate >/dev/null; then
            deactivate
            export PATH="$preserved_path"
        else
            path_remove PATH "$__RC_AUTO_VENV/bin"
            unset VIRTUAL_ENV
        fi
        unset __RC_AUTO_VENV __RC_AUTO_VENV_CANDIDATE
    fi
    if [[ -n $candidate ]]; then
        source "$candidate/bin/activate" || return
        # Activation scripts can use a canonical path different from candidate.
        __RC_AUTO_VENV=${VIRTUAL_ENV:-}
        __RC_AUTO_VENV_CANDIDATE=$candidate
    fi
    return 0
}
