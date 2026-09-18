#
# .bashrc - Basic env setup and resource script file
#

################################################################################
# $ECHO is real echo for interactive shells, a no-op otherwise. Used elsewhere for status messages (e.g.
# git-environment.sh's "Entering repository .." lines).
[[ -n $PS1 ]] && ECHO='echo -e' || ECHO=:

################################################################################
# source()
# Params: <file> - File to be sourced
#
# Consistent way to source resource files, overriding the built-in. Set SILENT_SOURCING=0 to log every file
# sourced (interactive shells only). Also records every file into __sourced_files, which _which()
# (40-user/50-aliases.sh) greps to show where an alias/function came from.
export SILENT_SOURCING=1
declare -a __sourced_files=()
__source_depth=0
function source() {
    local file=${1:-} verbose= status=0 previous
    [[ -n $file && -f $file ]] || return 0
    shift
    [[ -n $PS1 && $SILENT_SOURCING != 1 ]] && verbose=1
    # Track unique sources, rather than growing the array on every prompt/cd.
    for previous in "${__sourced_files[@]}"; do
        [[ $previous != "$file" ]] || break
    done
    [[ ${previous:-} == "$file" ]] || __sourced_files+=("$file")
    __source_depth=$((__source_depth + 2))
    [[ ! $verbose ]] || printf '%*ssource .. %s\n' "$__source_depth" '' "$file"
    builtin source "$file" "$@" || status=$?
    __source_depth=$((__source_depth - 2))
    return "$status"
}

################################################################################
# Loads ~/.rc recursively: within any directory, numbered 00-89 entries load first (numeric order), then
# unnumbered files, then numbered 90-99 entries last. A numbered entry that's a directory (00-core, 10-profile, 20-vendor,
# 30-team, 40-user, 90-post, ...) recurses with the same rule, so a tier's own files are ordered the same way
# the tiers themselves are. An unnumbered directory (e.g. templates/) is never recursed into or sourced --
# only unnumbered files are. $HOME/.rc is hardcoded below rather than $RC_PATH since $RC_PATH is defined by
# one of the files this loads.
function __rc_load_entry() {
    if [[ -d $1 ]]; then
        __rc_load "$1"
    elif [[ -f $1 ]]; then
        if [[ ${__RC_VARS_ONLY:-0} == 1 ]]; then
            [[ ${1##*/} != 00-vars.sh ]] || source "$1"
        else
            case "$1" in *.sh|*.bash) source "$1" ;;
                *) case "$(readlink -f -- "$1")" in *.sh|*.bash) source "$1" ;; esac ;;
            esac
        fi
    fi
}

function __rc_load() {
	local dir="$1" entry

	for entry in "$dir"/[0-8][0-9]-*; do
		__rc_load_entry "$entry"
	done
	for entry in "$dir"/*.{sh,bash}; do
		[[ -f "$entry" ]] || continue
		case "$(basename "$entry")" in
			[0-9][0-9]-*) continue ;;
			xx-*) continue ;;
		esac
		__rc_load_entry "$entry"
	done
	for entry in "$dir"/9[0-9]-*; do
		__rc_load_entry "$entry"
	done
}

function __rc_refresh_vars() {
    local __RC_VARS_ONLY=1
    __rc_load "$HOME/.rc"
    if declare -F rc_update_repo_paths >/dev/null; then rc_update_repo_paths; fi
}

__RC_LOADING=1
__rc_load "$HOME/.rc"
__RC_LOADING=0
__source_depth=0



################################################################################
# Uncomment the following to call the corresponding function prior to executing any command from the shell
# function pre_command() {
# 	# execute this prior to running any command
# }
# trap pre_command DEBUG

function format_prompt() {
	# The prompt is set by exporting the PS1 variable with any string
	if [ $SHOW_TARGET_IN_PROMPT -eq 1 -a "$BLD_TARGET" != "" ]; then
		TARGET_STRING="${FG_YELLOW}${BLD_TARGET}${FG_RESET} "
	else
		TARGET_STRING=""
	fi
	if [ ! -z "$DOCKER_IMAGE" ]; then
		DOCKER_STRING="[${FG_PINK}${DOCKER_IMAGE}${FG_RESET}] "
	else
		DOCKER_STRING=""
	fi
	# export PS1="$(git_prompt_format) ${PS_DIR}${PS_SYMB} "
	export PS1="${DOCKER_STRING}${PROMPT_PREFIX}${TARGET_STRING}$(git_prompt_format) ${PS_DIR}${PS_SYMB} "
}

function format_title() {
    local title_path=${PWD/#$HOME/\~}
    title_path=${title_path/#\/work\/$USER/}
    [[ -z $SRC_PATH_PREFIX ]] || title_path=${title_path/"$SRC_PATH_PREFIX"/..}
    printf '\033]0;%s%s\007' "$title_path" "$(git_title_format)"
}

function set_prompt() {
	# The following history commands allow us to track the history across different
	# sessions and log them all to the same file
	if [ $UNIFIED_HISTORY -eq 1 ]; then
		history -a	# write current history to the history file
		history -c	# clear current in memory history
		history -r	# read from history file into memory
	fi

	local prompt_dir prompt_file
	for prompt_dir in "$PROMPT_COMMAND_PATH"; do
		[[ -n $prompt_dir && -d $prompt_dir ]] || continue
		for prompt_file in "$prompt_dir"/*.{sh,bash}; do
			case "${prompt_file##*/}" in xx-*) continue ;; esac
			[[ -r $prompt_file ]] && source "$prompt_file"
		done
	done

	format_prompt
	format_title
}

# PROMPT_COMMAND_PATH (exported by ~/.rc/00-core/00-vars.sh, points at ~/.rc/prompt.d) holds files that should
# be sourced during the execution of PROMPT_COMMAND. This allows for updating env variables on each command if
# needed, or adjusting the information displayed in the prompt. To add a resource script to the prompt
# command path, just put the <file>.sh script in that directory.
export PROMPT_COMMAND=set_prompt

# All tiers and prompt helpers are now available to startup callbacks.
rc_emit shell_ready "$PWD" || :
