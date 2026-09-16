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
# (20-team/10-env.sh) greps to show where an alias/function came from.
export SILENT_SOURCING=1
declare -a __sourced_files=()
__source_depth=0
function source() {
	# echo "$FUNCNAME(argc:$# argv:$@)"
	file=$1
	local verbose; [[ -n $PS1 && $SILENT_SOURCING != 1 ]] && verbose=1
	if [[ ! -z "$file" && -f $file ]]; then
		__sourced_files+=("$file")
		(( __source_depth += 2))
		[[ $verbose ]] && printf '%*ssource .. %s\n' $__source_depth "" $file
		. $file
		(( __source_depth -= 2))
	elif [[ ! -z "$file" ]]; then
		[[ $verbose ]] && echo -e "File [$file] not found."
	fi
}

################################################################################
# Loads ~/.rc recursively: within any directory, numbered 00-89 entries load first (numeric order), then
# unnumbered files, then numbered 90-99 entries last. A numbered entry that's a directory (00-core, 10-vendor,
# 20-team, 30-user, 90-post, ...) recurses with the same rule, so a tier's own files are ordered the same way
# the tiers themselves are. An unnumbered directory (e.g. templates/) is never recursed into or sourced --
# only unnumbered files are. $HOME/.rc is hardcoded below rather than $RC_PATH since $RC_PATH is defined by
# one of the files this loads.
function __rc_load_entry() {
	if [[ -d "$1" ]]; then
		__rc_load "$1"
	elif [[ -f "$1" ]]; then
		# readlink -f resolves symlinks first: a symlink named without a .sh/.bash suffix of its own (but
		# pointing at a real script) would otherwise be silently skipped, even though -f above already
		# confirmed it resolves to a regular file. A no-op for non-symlinks.
		case "$(readlink -f -- "$1")" in
			*.sh | *.bash) source "$1" ;;
		esac
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

__rc_load "$HOME/.rc"
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
	echo -ne "\033]0;${PWD}$(git_title_format)\007" | sed -e "s|/home/${USER}|~|" -e "s|/work/${USER}||" -e "s|${SRC_PATH_PREFIX}|..|"
}

function set_prompt() {
	# The following history commands allow us to track the history across different
	# sessions and log them all to the same file
	if [ $UNIFIED_HISTORY -eq 1 ]; then
		history -a	# write current history to the history file
		history -c	# clear current in memory history
		history -r	# read from history file into memory
	fi

	if [ -d $PROMPT_COMMAND_PATH ]; then
		for i in ${PROMPT_COMMAND_PATH}/*.{sh,bash}; do
			if [ -r "$i" ]; then
				. $i
			fi
		done
		unset i
	fi

	format_prompt
	format_title
}

# PROMPT_COMMAND_PATH (exported by ~/.rc/00-core/00-vars.sh, points at ~/.rc/prompt.d) holds files that should
# be sourced during the execution of PROMPT_COMMAND. This allows for updating env variables on each command if
# needed, or adjusting the information displayed in the prompt. To add a resource script to the prompt
# command path, just put the <file>.sh script in that directory.
export PROMPT_COMMAND=set_prompt
