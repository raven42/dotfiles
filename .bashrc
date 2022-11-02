#
# .bashrc - Basic env setup and resource script file
#

# Note: Build alias definitions moved to ~/.default_rc or ${GIT_ROOT}/.rc/rc files
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
export MODULEPATH=$HOME/.default/modulefiles:/usr/share/Modules/modulefiles:/etc/modulefiles
#export PATH=.:~/bin:~/sbin:~/bin/cron:~/.local/bin:/bin:/usr/sbin:/usr/bin:/usr/local/bin
export PATH=/bin:/usr/sbin:/usr/bin:/usr/local/bin
#export PYTHONPATH=~/.local/lib/python3.5/site-packages
export PYTHONPATH=
export SHOW_TARGET_IN_PROMPT=1
export TAGDIR=$HOME/.default/tags
export TMOUT=0
export TZ=/usr/share/zoneinfo/US/Central
export UNIFIED_HISTORY=0
export USE_UNICODE=1
export VISUAL=vim

# If not an interactive shell, don't proceed any further (ex. SCP commands)
# need to do at least basic PATH setup and other common env vars
if [ -z "$PS1" ]; then
	ECHO=:
else
	ECHO='echo -e'
fi

shopt -s checkwinsize

if [ "$(command -v module)" ]; then
	module purge
fi

# External resource / script files
BLD_TARGET_SCRIPT=bld_target.sh
DEFAULT_RC_PATH=${HOME}/.default
CHANGE_DIR_SCRIPT=${HOME}/sbin/change_dir.sh
COMMON_RC=${DEFAULT_RC_PATH}/common_rc.sh
POST_RC=${DEFAULT_RC_PATH}/post_rc.sh
DIRCOLORS=${HOME}/.dircolors
GIT_DEFAULT_RC=${DEFAULT_RC_PATH}/repo_rc.sh
GIT_RC_PATH=${GIT_ROOT}/.rc
GIT_RC=${GIT_RC_PATH}/rc
GIT_TAGS_PATH=${GIT_RC_PATH}/tags
GIT_COMPLETION=${HOME}/sbin/git-completion.bash
GIT_PROMPT=${HOME}/sbin/git-prompt.sh
NERDTREE_GEN_SCRIPT=${HOME}/sbin/gen_nerdtree_bookmarks.py
NERDTREE_BOOKMARKS=${GIT_RC_PATH}/NERDTreeBookmarks
NERDTREE_DEF_BOOKMARKS=${DEFAULT_RC_PATH}/NERDTreeDefaultBookmarks
PRIVATE_RC_PATH=${HOME}/.private
PRIVATE_RC=${PRIVATE_RC_PATH}/private_rc.sh
RETAG_SCRIPT=${HOME}/bin/retag

# colors for ls, etc.  Prefer ~/.dir_colors #64489
if ! shopt -q login_shell ; then # We're not a login shell
	for i in /etc/profile.d/*.sh; do
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

# If present, source ${CHANGE_DIR_SCRIPT} for directory tracking with 'cd'
if [[ -f ${CHANGE_DIR_SCRIPT} ]]; then
	. ${CHANGE_DIR_SCRIPT}
fi

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

if [ -f $GIT_COMPLETION ]; then
	. $GIT_COMPLETION
fi
if [ -f $GIT_PROMPT ]; then
	. $GIT_PROMPT
fi

if [ $GIT_REPO ]; then
	$ECHO "Setting up GIT environment variables for ${GIT_REPO}..."
	if [ ! -d ${GIT_ROOT} ]; then
		$ECHO "GIT_ROOT:${GIT_ROOT} not found."
	else
		if [[ ${GIT_ROOT} =~ ${USER} ]]; then
			if [ ! -d ${GIT_RC_PATH} -a -w ${GIT_ROOT} ]; then
				$ECHO "Creating repo rc directory at ${GIT_RC_PATH}..."
				mkdir ${GIT_RC_PATH}
			fi
			if [ ! -d ${GIT_TAGS_PATH} -a -w ${GIT_RC_PATH} ]; then
				$ECHO "Creating ctags output directory at ${GIT_TAGS_PATH}..."
				mkdir ${GIT_TAGS_PATH}
			fi
		fi
		if [ -f ${GIT_RC} ]; then
			rc_spec=${GIT_RC}
		elif [ -f ${GIT_DEFAULT_RC} ]; then
			if [[ ${GIT_ROOT} =~ ${USER} ]]; then
				$ECHO "rc spec not found. Generating defaults at ${GIT_RC}..."
				if [ ! -f ${GIT_RC} -a -w ${GIT_RC_PATH} ]; then
					cp ${GIT_DEFAULT_RC} ${GIT_RC}
				fi
				rc_spec=${GIT_RC}
			else
				$ECHO "rc (${GIT_RC}) spec not found. Using defaults."
				rc_spec=${GIT_DEFAULT_RC}
			fi
		else
			$ECHO "rc spec [${GIT_DEFAULT_RC}] not found. No defaults to use."
		fi
	fi

	if [[ ${GIT_ROOT} =~ ${USER} ]]; then

		# Look for REPO specific NERDTree File and if not exists, then generate it
		if [ -f ${NERDTREE_GEN_SCRIPT} -a -f ${NERDTREE_DEF_BOOKMARKS} ]; then
			if [ -f ${NERDTREE_BOOKMARKS} ]; then
				if [[ ${NERDTREE_DEF_BOOKMARKS} -nt ${NERDTREE_BOOKMARKS} ]]; then
					$ECHO "NERDTree Bookmarks out of date. Generating new file..."
					${NERDTREE_GEN_SCRIPT} -q -i ${NERDTREE_DEF_BOOKMARKS} -o ${NERDTREE_BOOKMARKS}
				fi
			else
				$ECHO "Generating NERDTree Bookmarks file..."
				${NERDTREE_GEN_SCRIPT} -q -i ${NERDTREE_DEF_BOOKMARKS} -o ${NERDTREE_BOOKMARKS}
			fi
		fi

		# Look for TAG files and if none are found, generate new ones
		if [ ! "$(ls -A $GIT_TAGS_PATH)" ]; then
			$ECHO ' No TAGFILES found. Generating new tags in the background...'
			nohup ${RETAG_SCRIPT} -a --dir ${GIT_TAGS_PATH} 2>&1 1> ${HOME}/log/retag_${GIT_REPO}.log &
		fi

		# Look for deprecated build target scripts
		if [ -f ${GIT_RC_PATH}/bld_target ]; then
			$ECHO "Deprecated resource script found... [${GIT_RC_PATH}/bld_target]"
			$ECHO "Please move to the new location...  [${GIT_RC_PATH}/${BLD_TARGET_SCRIPT}]"
			$ECHO "  mv ${GIT_RC_PATH}/bld_target ${GIT_RC_PATH}/${BLD_TARGET_SCRIPT}"
		fi
		if [ -f ${GIT_RC_PATH}/target ]; then
			$ECHO "Deprecated resource script found... [${GIT_RC_PATH}/target]"
			$ECHO "Please move to the new location...  [${GIT_RC_PATH}/${BLD_TARGET_SCRIPT}]"
			$ECHO "  mv ${GIT_RC_PATH}/target ${GIT_RC_PATH}/${BLD_TARGET_SCRIPT}"
		fi
	fi
fi

# Include the default alias / resource definitions
if [ -f ${COMMON_RC} ]; then
	. ${COMMON_RC}
elif [ -f ${DEFAULT_RC_PATH}/common_rc ]; then
	$ECHO "Deprecated resource script found... [${DEFAULT_RC_PATH}/common_rc]"
	$ECHO "Please move to the new location...  [${COMMON_RC}]"
	$ECHO "   mv ${DEFAULT_RC_PATH}/common_rc ${COMMON_RC}"
	$ECHO "Sourcing this for now..."
	. ${DEFAULT_RC_PATH}/common_rc
fi
[[ -f ${PRIVATE_RC} ]] && . ${PRIVATE_RC}

# Load repo / view specific resource definitions
if [ ${rc_spec} ]; then
	. ${rc_spec}
	$ECHO "  RC SPEC:${rc_spec}"
	$ECHO "  TAGDIR:${TAGDIR}"
fi

#Display info
export DISPLAY

function format_prompt() {
	# The prompt is set by exporting the PS1 variable with any string
	if [ $GIT_REPO ]; then
		if [[ ! ${GIT_ROOT} =~ ${USER} ]]; then
			PS_COLOR=${FG_PINK}
		elif [[ ${USER_HOSTNAME} =~ ${HOSTNAME} ]]; then
			PS_COLOR=${FG_ORANGE}
		else
			PS_COLOR=${FG_CYAN}
		fi

		if [ -f ${GIT_RC_PATH}/${BLD_TARGET_SCRIPT} ]; then
			. ${GIT_RC_PATH}/${BLD_TARGET_SCRIPT}
		elif [ -f ${DEFAULT_RC_PATH}/${BLD_TARGET_SCRIPT} ]; then
			. ${DEFAULT_RC_PATH}/${BLD_TARGET_SCRIPT}
		fi

		if [ $SHOW_TARGET_IN_PROMPT -eq 1 -a "$BLD_TARGET" != "" ]; then
			TARGET_STRING="${FG_YELLOW}${BLD_TARGET}${FG_RESET} "
		else
			TARGET_STRING=""
		fi
		pyuniti_config=${HOME}/.pyuniti/config.ini
		if [ -f ${pyuniti_config} ]; then
			if [ $(grep -c "^tbc=" ${pyuniti_config}) -eq 1 ]; then
				TBC=$(grep "^tbc=" ${pyuniti_config} | sed -e 's|^tbc.*/||')
				TARGET_STRING+="${FG_MAGENTA}${TBC}${FG_RESET} "
			fi
		fi
		# branch code $'\xee\x82\xa0'
		PS_INFO="$GIT_REPO\$(__git_ps1)"
		# PS_INFO=$'$GIT_REPO \xee\x82\xa0$(__git_ps1)'
	else
		PS_COLOR=${FG_GREEN}
		PS_INFO="${PS_HOST}${FG_YELLOW}\$(__git_ps1)${FG_RESET}"
		TARGET_STRING=""
	fi
	export PS1="${TARGET_STRING}${PS_COLOR}${PS_INFO}${FG_RESET} ${PS_DIR}${PS_SYMB} "
}

function format_title() {
	# To change the window title, do an 'echo -ne "\033]0;<string>\007"'
	if [ $GIT_REPO ]; then
		if [ $USE_UNICODE -eq 1 ]; then
			TITLE_INFO="\xee\x82\xa0$(__git_ps1)"
		else
			TITLE_INFO="$(__git_ps1)"
		fi
	else
		TITLE_INFO="${USER}"
	fi
	echo -ne "\033]0;${PWD} ${TITLE_INFO}\007" | sed -e "s|/home/${USER}|~|" -e "s|/work/${USER}||" -e "s|${SRC_PATH_PREFIX}|..|"
}

function set_prompt() {
	# The following history commands allow us to track the history across different
	# sessions and log them all to the same file
	if [ $UNIFIED_HISTORY -eq 1 ]; then
		history -a	# write current history to the history file
		history -c	# clear current in memory history
		history -r	# read from history file into memory
	fi

	format_prompt
	format_title
}

export PROMPT_COMMAND=set_prompt

# Source the post_rc file if needed
if [ -f ${POST_RC} ]; then
	. ${POST_RC}
elif [ -f ${DEFAULT_RC_PATH}/post_rc ]; then
	$ECHO "Deprecated resource script found... [${DEFAULT_RC_PATH}/post_rc]"
	$ECHO "Please move to the new location...  [${POST_RC}]"
	$ECHO "   mv ${DEFAULT_RC_PATH}/post_rc ${POST_RC}"
	$ECHO "Sourcing this for now..."
	. ${DEFAULT_RC_PATH}/post_rc
fi
