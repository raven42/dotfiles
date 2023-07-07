#
# .bashrc - Basic env setup and resource script file
#

alias dirs='dirs -v'
alias githome='git --git-dir $HOME/.cfg/ --work-tree $HOME'
alias ls="ls -F -T 0 --color=auto"	# Add class indicator, spaces instead of tabs
alias rebash='unset LOADEDMODULES _LMFILES_ ; source ~/.bashrc'
alias scp="scp -oStrictHostKeyChecking=no"
alias ssh="ssh -e  -oStrictHostKeyChecking=no"
alias telnet="telnet -e ^B"
alias vi="vim"

# Setup our environment:
export AUTOSAVE=0							# by default, don't autosave in vim
export EDITOR=vim
export HISTTIMEFORMAT='%m/%d/%Y-%T '
export HISTCONTROL=ignoredups				# Don't save commands leading with a whitespace, or duplicated commands
export HISTFILE=$HOME/.history-$HOSTNAME	# Specific history file per host
export HISTIGNORE="pwd:ls:ls -al:ll:history:h:h[dh]:h [0-9]*:h[dh] [0-9]*"
export HISTSIZE=5000
export HISTFILESIZE=999999					# Enable huge history
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LD_LIBRARY_PATH=~/local/lib:/lib:/usr/lib:/usr/local/lib
export LD_RUN_PATH=~/local/lib:/lib:/usr/lib:/usr/local/lib:~/local/lib
export LYNX_CFG=~/.lynxrc
export MAKEFLAGS=-s
export MANPATH=~/local/man:/usr/man:/usr/local/man:/usr/share/man
export MODULEPATH=$HOME/.default/modulefiles:$HOME/.private/modulefiles:/usr/share/modules/modulefiles:/etc/modulefiles
#export PATH=.:~/bin:~/sbin:~/bin/cron:~/.local/bin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
export PATH=/bin:/usr/sbin:/usr/bin:/usr/local/bin:/cmd
#export PYTHONPATH=~/.local/lib/python3.5/site-packages
export PYTHONPATH=
export SHOW_TARGET_IN_PROMPT=1
export SILENT_SOURCING=1
export TAGDIR=$HOME/.default/tags
export TMOUT=0
export TZ=/usr/share/zoneinfo/US/Central
export UNIFIED_HISTORY=0
export USE_UNICODE=1
export VISUAL=vim
export GITRC_ENVIRONMENT=1

# If not an interactive shell, don't proceed any further (ex. SCP commands)
# need to do at least basic PATH setup and other common env vars
if [ -z "$PS1" ]; then
	ECHO=:
	SOURCE_ECHO=:
else
	ECHO='echo -e'
	if [[ $SILENT_SOURCING == 1 ]]; then
		SOURCE_ECHO=:
	else
		SOURCE_ECHO='echo -e'
	fi
fi

shopt -s checkwinsize

##############################
# initialize_git_repository()
#
# Params: GIT_RC_PATH - The path to the GIT_ROOT/.rc path controlled and sourced by git-environment.bash
#
# This function is called from within the git-environment.bash:update_git_environment() function after we've changed
# directories and have updated the git environment variables. This will create the GIT_RC_PATH and GIT_TAGS_PATH
# directories if needed. If there are no tag files found in the GIT_TAGS_PATH, then it will use the RETAG_SCRIPT
# to start a background process generating the ctags files. If there is a NERDTREE_BOOKMARKS file and the default
# one has been modified since the existing one, then it will generate a new bookmarks file based on the default.
#
function initialize_git_repository() {

	if [[ $GITRC_ENVIRONMENT == 0 ]]; then
		return
	fi

	# If we are not in a git repository, just ignore this
	if [[ -z "$GIT_REPO" ]]; then
		export __CACHED_GIT_ROOT=''
		return
	fi
	GIT_RC_PATH=$1

	GIT_TAGS_PATH=$GIT_RC_PATH/tags
	NERDTREE_BOOKMARKS=$GIT_RC_PATH/NERDTreeBookmarks

	if [[ "$__CACHED_GIT_ROOT" != "$GIT_ROOT" ]]; then
		export __CACHED_GIT_ROOT=$GIT_ROOT

		if [ ! -d $GIT_ROOT ]; then

			$ECHO "GIT_ROOT:$GIT_ROOT not found - Ignoring any initial setup."

		elif [[ $GIT_ROOT =~ $USER ]]; then

			# If not in a $USER path, then don't attempt to create any resource files

			# Setup some GIT repository defaults
			$SOURCE_ECHO "init git .. [$GIT_REPO:$GIT_RC_PATH]"

			if [ ! -d $GIT_RC_PATH -a -w $GIT_ROOT ]; then
				$ECHO "Creating repo rc directory at $GIT_RC_PATH..."
				mkdir $GIT_RC_PATH
			fi
			if [ ! -d $GIT_TAGS_PATH -a -w $GIT_RC_PATH ]; then
				$ECHO "Creating ctags output directory at $GIT_TAGS_PATH..."
				mkdir $GIT_TAGS_PATH
			fi

			# Look for REPO specific NERDTree File and if not exists, then generate it
			if [[ -f $NERDTREE_GEN_SCRIPT && -f $NERDTREE_DEF_BOOKMARKS ]]; then
				if [[ -f $NERDTREE_BOOKMARKS && $NERDTREE_DEF_BOOKMARKS -nt $NERDTREE_BOOKMARKS ]]; then
					$ECHO "NERDTree Bookmarks out of date. Generating new file..."
					$NERDTREE_GEN_SCRIPT -q -i $NERDTREE_DEF_BOOKMARKS -o $NERDTREE_BOOKMARKS
				elif [[ ! -f $NERDTREE_BOOKMARKS ]]; then
					$ECHO "Generating NERDTree Bookmarks file..."
					$NERDTREE_GEN_SCRIPT -q -i $NERDTREE_DEF_BOOKMARKS -o $NERDTREE_BOOKMARKS
				fi
			fi

			# Look for TAG files and if none are found, generate new ones
			if [ ! "$(ls -A $GIT_TAGS_PATH)" ]; then
				$ECHO " No TAGFILES found. Generating new tags in the background at $GIT_TAGS_PATH..."
				nohup $RETAG_SCRIPT -a --dir $GIT_TAGS_PATH 2>&1 1> $HOME/var/log/retag_$GIT_REPO.log &
			fi
		fi
	fi
}

###########
# source()
# Params: <file> - File to be sourced
#
# This function will help provide a consisten means to source any resource files overriding the default built-in
function source() {
	# echo "$FUNCNAME(argc:$# argv:$@)"
	file=$1
	if [[ ! -z "$file" && -f $file ]]; then
		$SOURCE_ECHO "sourcing .. [$file]"
		. $file
	elif [[ ! -z "$file" ]]; then
		$SOURCE_ECHO "File [$file] not found."
	fi
}

# External resource / script files
DEFAULT_RC_PATH=${HOME}/.default
PRIVATE_RC_PATH=${HOME}/.private
BLD_TARGET_SCRIPT=${PRIVATE_RC_PATH}/bld_target.sh
CHANGE_DIR_SCRIPT=${HOME}/sbin/change_dir.sh
COMMON_RC=${DEFAULT_RC_PATH}/common_rc.sh
DIRCOLORS=${HOME}/.dircolors
NERDTREE_DEF_BOOKMARKS=${PRIVATE_RC_PATH}/NERDTreeDefaultBookmarks
NERDTREE_GEN_SCRIPT=${HOME}/sbin/gen_nerdtree_bookmarks.py
POST_RC=${PRIVATE_RC_PATH}/post_rc.sh
PRIVATE_RC=${PRIVATE_RC_PATH}/private_rc.sh
RETAG_SCRIPT=${HOME}/sbin/retag.sh

# colors for ls, etc.  Prefer ~/.dir_colors #64489
if ! shopt -q login_shell ; then # We're not a login shell
	for i in /etc/profile.d/*.sh; do
		if [ -r "$i" ]; then
			. $i
		fi
	done
	unset i

	for i in ${HOME}/bin/completions/*.bash; do
		if [ -r "$i" ]; then
			. $i
		fi
	done
	unset i
fi

if [[ -f ${DIRCOLORS} ]]; then
	eval `dircolors -b ${DIRCOLORS}`
elif [[ -f /etc/DIR_COLORS ]]; then
	eval `dircolors -b /etc/DIR_COLORS`
fi

# First purge any modules so we can start fresh if any were loaded
[[ "$(command -v module)" ]] && module purge

# Source various other bash resource scripts to enhance our shell environment
source $HOME/sbin/git-completion.bash
source $HOME/sbin/git-prompt.sh
source $CHANGE_DIR_SCRIPT
source $COMMON_RC
source $PRIVATE_RC
source $HOME/sbin/git-environment.bash		# should be after PRIVATE_RC so user settings can be applied

# 030m - Black
# 031m - Red
# 032m - Green
# 033m - Yellow
# 034m - Blue
# 035m - Purple
# 036m - Cyan
# 037m - White
# 0m   - Reset

FG_BLACK="\[\033[0;30m\]"
FG_RED="\[\033[0;31m\]"
FG_GREEN="\[\033[0;32m\]"
FG_YELLOW="\[\033[0;33m\]"
FG_BLUE="\[\033[0;34m\]"
FG_MAGENTA="\[\033[0;35m\]"
FG_CYAN="\[\033[0;36m\]"
FG_WHITE="\[\033[0;37m\]"
FG_RESET="\[\033[0;0m\]"

FG_PINK="\[\033[38;5;212m\]"
FG_ORANGE="\[\033[38;5;202m\]"

PS_DATE="\d"		# Date in "Tue May 26" format
PS_HOST="\h"		# Hostname to first '.'
PS_FULLHOST="\h"	# Full hostname
PS_JOBS="\j"		# Number of jobs currently managed by shell
PS_DEVNAME="\l"		# basename of the shell's terminal device name
PS_SHELL="\s"		# name of the shell
PS_24TIME="\t"		# Time in 24 hour HH:MM:SS format
PS_12TIME="\T"		# Time in 12 hour HH:MM:SS format
PS_TIME="\@"		# Time in am/pm format
PS_USER="\u"		# Username
PS_CWD="\w"			# Current working directory
PS_DIR="\W"			# Basename of current working directory
PS_HIST="\!"		# History number of this command
PS_CMDNUM="\#"		# Command number of this command
PS_SYMB="\$"		# If you are root '#', else '$'
PS_NL="\n"			# Newline character
PS_CR="\r"			# Carriage return
PS_ESC="\e"			# Escape character
PS_BELL="\a"		# Bell character

# Display info
export DISPLAY

function format_prompt() {
	# The prompt is set by exporting the PS1 variable with any string
	if [ $SHOW_TARGET_IN_PROMPT -eq 1 -a "$BLD_TARGET" != "" ]; then
		TARGET_STRING="${FG_YELLOW}${BLD_TARGET}${FG_RESET} "
	else
		TARGET_STRING=""
	fi
	export PS1="${TARGET_STRING}$(git_prompt_format) ${PS_DIR}${PS_SYMB} "
}

function format_title() {
	echo -ne "\033]0;${PWD} $(git_title_format)\007" | sed -e "s|/home/${USER}|~|" -e "s|/work/${USER}||" -e "s|${SRC_PATH_PREFIX}|..|"
}

function set_prompt() {
	# The following history commands allow us to track the history across different
	# sessions and log them all to the same file
	if [ $UNIFIED_HISTORY -eq 1 ]; then
		history -a	# write current history to the history file
		history -c	# clear current in memory history
		history -r	# read from history file into memory
	fi

	if [ -f $BLD_TARGET_SCRIPT ]; then
		# $ECHO "sourcing .. [$BLD_TARGET_SCRIPT]"
		. $BLD_TARGET_SCRIPT
	else
		unset BLD_TARGET
	fi

	format_prompt
	format_title
}

export PROMPT_COMMAND=set_prompt

source $POST_RC
