# Terminal type tweaking...
#if [ $TERM = rxvt ]; then
#	TERM=xterm
#	export TERM
#fi

# Note: Build alias definitions moved to ~/.default_rc or ${GIT_ROOT}/.rc/rc files
alias githome='/usr/bin/git --git-dir $HOME/.cfg/ --work-tree $HOME'
alias ls="ls -F -T 0 --color=auto"	# Add class indicator, spaces instead of tabs
alias rebash='source ~/.bashrc'
alias scp="scp -oStrictHostKeyChecking=no"
alias ssh="ssh -oStrictHostKeyChecking=no"
alias telnet="telnet -e ^B"
alias vi="vim"

# Setup our environment:
export EDITOR=/usr/bin/vim
export HISTTIMEFORMAT='%m/%d/%Y-%T '
export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8
export LD_LIBRARY_PATH=~/local/lib:/lib:/usr/lib:/usr/local/lib
export LD_RUN_PATH=~/local/lib:/lib:/usr/lib:/usr/local/lib:~/local/lib
export MAKEFLAGS=-s
export MANPATH=~/local/man:/usr/man:/usr/local/man:/usr/share/man
export PATH=.:~/bin:~/bin/cron:~/.local/bin:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/tools/bsneng/bin:/projects/bsnswtools/bin/fos:/projects/bsnswtools/bin/extn:/tools/bsnbld/accupara/build
export PYTHONPATH=~/.local/lib/python3.5/site-packages
export TMOUT=0
export TZ=/usr/share/zoneinfo/US/Central
export VISUAL=/usr/bin/vim

shopt -s checkwinsize

# External resource / script files
DEFAULT_RC_PATH=${HOME}/.default
COMMON_RC=${DEFAULT_RC_PATH}/common_rc
POST_RC=${DEFAULT_RC_PATH}/post_rc
DIRCOLORS=${HOME}/.dircolors
GIT_DEFAULT_RC=${DEFAULT_RC_PATH}/repo_rc
GIT_RC_PATH=${GIT_ROOT}/.rc
GIT_RC=${GIT_RC_PATH}/rc
GIT_TAGS_PATH=${GIT_RC_PATH}/tags
GIT_COMPLETION=/tools/bsnbld/scripts/gittools/shell/git-completion.bash
GIT_PROMPT=/tools/bsnbld/scripts/gittools/shell/git-prompt.sh
NERDTREE_GEN_SCRIPT=${HOME}/bin/gen_nerdtree_bookmarks.py
NERDTREE_BOOKMARKS=${GIT_RC_PATH}/NERDTreeBookmarks
NERDTREE_DEF_BOOKMARKS=${DEFAULT_RC_PATH}/NERDTreeDefaultBookmarks
USER_HOSTNAME="bsnvdga0120"

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

# 030m - Black
# 031m - Red
# 032m - Green
# 033m - Yellow
# 034m - Blue
# 035m - Purple
# 036m - Cyan
# 037m - White
# 0m   - reset

FG_BLK="\[\033[0;30m\]"
FG_RED="\[\033[0;31m\]"
FG_GRN="\[\033[0;32m\]"
FG_YLW="\[\033[0;33m\]"
FG_BLU="\[\033[0;34m\]"
FG_PURP="\[\033[0;35m\]"
FG_CYAN="\[\033[0;36m\]"
FG_WHT="\[\033[0;37m\]"
FG_RST="\[\033[0;0m\]"

FG_PINK="\[\033[38;5;212m\]"
FG_ORG="\[\033[38;5;202m\]"

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
PS_WD="\w"			# Current working directory
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
	echo "Setting up GIT environment variables for ${GIT_REPO}..."
	if [ ! -d ${GIT_ROOT} ]; then
		echo "GIT_ROOT:${GIT_ROOT} not found."
	else
		if [ ! -f ${GIT_RC} ]; then
			if [[ ${GIT_ROOT} =~ ${USER} ]]; then
				echo "rc spec not found. Generating defaults at ${GIT_RC}..."
				if [ ! -d ${GIT_RC_PATH} -a -w ${GIT_ROOT} ]; then
					mkdir ${GIT_RC_PATH}
				fi
				if [ ! -f ${GIT_RC} -a -w ${GIT_RC_PATH} ]; then
					cp ${GIT_DEFAULT_RC} ${GIT_RC}
					mkdir ${GIT_TAGS_PATH}
				fi
				rc_spec=${GIT_RC}
			else
				echo "rc (${GIT_RC}) spec not found. Using defaults."
				rc_spec=${GIT_DEFAULT_RC}
			fi
		else
			rc_spec=${GIT_RC}
		fi
	fi

	if [[ ! ${GIT_ROOT} =~ ${USER} ]]; then
		PS_COLOR=${FG_PINK}
	elif [[ ${HOSTNAME} =~ ${USER_HOSTNAME} ]]; then
		PS_COLOR=${FG_ORG}
	else
		PS_COLOR=${FG_CYAN}
	fi
	PS_INFO="$GIT_REPO\$(__git_ps1)"
	TITLE_INFO="\xee\x82\xa0$(__git_ps1)"

	# Look for REPO specific NERDTree File and if not exists, then generate it
	if [ -f ${NERDTREE_GEN_SCRIPT} -a -f ${NERDTREE_DEF_BOOKMARKS} ]; then
		if [ -f ${NERDTREE_BOOKMARKS} ]; then
			if [[ ${NERDTREE_DEF_BOOKMARKS} -nt ${NERDTREE_BOOKMARKS} ]]; then
				echo "NERDTree Bookmarks out of date. Generating new file..."
				${NERDTREE_GEN_SCRIPT} -q -i ${NERDTREE_DEF_BOOKMARKS} -o ${NERDTREE_BOOKMARKS}
			fi
		else
			echo "Generating NERDTree Bookmarks file..."
			${NERDTREE_GEN_SCRIPT} -q -i ${NERDTREE_DEF_BOOKMARKS} -o ${NERDTREE_BOOKMARKS}
		fi
	fi
else
	PS_COLOR=${FG_GRN}
	PS_INFO="${PS_HOST}${FG_YLW}\$(__git_ps1)${FG_RST}"
	TITLE_INFO="${USER}"
fi

# Include the default alias / resource definitions
if [ -f ${COMMON_RC} ]; then
	. ${COMMON_RC}
fi

# Load repo / view specific resource definitions
if [ ${rc_spec} ]; then
	. ${rc_spec}
	echo "  RC SPEC:${rc_spec}"
	echo "  TAGDIR:${TAGDIR}"
fi

#Display info
export DISPLAY

function format_prompt() {
	# The prompt is set by exporting the PS1 variable with any string
	if [ $GIT_REPO ]; then
		if [ -f ${GIT_RC_PATH}/swbd ]; then
			PLATFORM_PATH=${GIT_RC_PATH}/swbd
		else
			PLATFORM_PATH=${DEFAULT_RC_PATH}/swbd
		fi
		. ${PLATFORM_PATH}

		if [ $SWBD ]; then
			PLATFORM_STRING="${FG_YLW}SWBD-${SWBD:4} "
		fi
	else
		PLATFORM_STRING=""
	fi
	export PS1="[${PLATFORM_STRING}${PS_COLOR}${PS_INFO}${FG_RST}] ${PS_DIR}${PS_SYMB} "
}

function format_title() {
	# To change the window title, do an 'echo -ne "\033]0;<string>\007"'
	if [ $GIT_REPO ]; then
		echo -ne "\033]0;${TITLE_INFO} ${PWD}\007" | sed -e "s/\/home\/${USER}/~/" -e "s/\/work\/${USER}//" -e "s|/zzz/work[0-9][0-9]\(.*\)/.*${GIT_REPO}|\1|" -e "s|/vobs|/.|" -e "s|/projects|.|" -e "s|/springboard|.|"
	else
		echo -ne "\033]0;${TITLE_INFO} ${PWD}\007" | sed -e "s/\/home\/${USER}/~/" -e "s|/vobs|/.|" -e "s|/projects|.|" -e "s|/springboard|.|"
	fi
}

function set_prompt() {
	format_prompt
	format_title
}

if [ $TERM = xterm ]; then
	PROMPT_COMMAND=set_prompt
fi

# Source the post_rc file if needed
if [ -f ${POST_RC} ]; then
	. ${POST_RC}
fi
