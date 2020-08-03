# Terminal type tweaking...
#if [ $TERM = rxvt ]; then
#	TERM=xterm
#	export TERM
#fi

#echo "Something witty..."

# Note: Directory alias definitions moved to ~/.default_rc or ~/.{branch}_rc files
alias bcl='make -f makefile.sb clean no_depend=1'
alias githome='/usr/bin/git --git-dir $HOME/.cfg/ --work-tree $HOME'
#alias ls="ls -F"
alias rebash='source ~/.bashrc'
alias view="cleartool setview"
alias telnet="telnet -e ^B"
alias scp="scp -oStrictHostKeyChecking=no"
alias ssh="ssh -oStrictHostKeyChecking=no"
alias unco='cleartool unco -rm'
alias vi="vim"

# Setup our environment:
PATH=.:~/bin:~/bin/cron:~/.local/bin:/bin:/usr/sbin:/usr/openwin/bin:/usr/atria/bin:/usr/rational/local/bin:/usr/ucb:/usr/bin:/usr/X11R6/bin:/import/local/bin:/import/local/ar/bin:/usr/ccs/bin:/opt/slickedit/bin:/usr/ccs/bin:/usr/local/bin:~swuser/bin:~cjohnson/bin:/corp/global/tools/bin:/corp/global/tools/bin/gittools:/tools/bsneng/bin:/projects/bsnswtools/bin/fos:/projects/bsnswtools/bin/extn:~/bin/fos:/tools/bsnbld/accupara/build
export PATH

PYTHONPATH=~/.local/lib/python3.5/site-packages
export PYTHONPATH

export EDITOR=/usr/bin/vim
export VISUAL=/usr/bin/vim

HISTTIMEFORMAT='%m/%d/%Y-%T '
export HISTTIMEFORMAT

TZ=/usr/share/zoneinfo/US/Central
export TZ

# These were set to en_US.UTF-8
LANG=en_US.UTF-8
export LANG
LANGUAGE=en_US.UTF-8
export LANGUAGE
LC_ALL=en_US.UTF-8
export LC_ALL

LD_LIBRARY_PATH=~/local/lib:/lib:/usr/lib:/usr/local/lib:$LD_LIBRARY_PATH
export LD_LIBRARY_PATH
LD_RUN_PATH=~/local/lib:/lib:/usr/lib:/usr/local/lib:~/local/lib:$LD_RUN_PATH
export LD_RUN_PATH
MANPATH=~/local/man:/usr/man:/usr/local/man:/usr/share/man:/usr/atria/doc/man:~/opt/gcc-4.1.0-glibc-2.3.6/powerpc-750-linux-gnu/man
export MANPATH
TMOUT=0
export TMOUT
MAKEFLAGS=-s
export MAKEFLAGS

ZZZ_HOME=/zzz/work06/dhegland
export ZZZ_HOME

# Override any built in make commands
make()
{
	if [ -f ~/bin/make ]; then
		~/bin/make $@
	else
		/usr/bin/make $@
	fi
}

shopt -s checkwinsize

# colors for ls, etc.  Prefer ~/.dir_colors #64489
if ! shopt -q login_shell ; then # We're not a login shell
	for i in /etc/profile.d/*.sh; do
		if [ -r "$i" ]; then
			. $i
		fi
	done
	unset i
fi
if [[ -f ~/.dircolors ]]; then
	eval `dircolors -b ~/.dircolors`
elif [[ -f /etc/DIR_COLORS ]]; then
	eval `dircolors -b /etc/DIR_COLORS`
fi
alias ls="ls -F -T 0 --color=auto"

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

. /tools/bsnbld/scripts/gittools/shell/git-completion.bash
. /tools/bsnbld/scripts/gittools/shell/git-prompt.sh

if [ $GIT_REPO ]; then
	echo "  Setting up GIT environment variables..."
	if [ ! -d ${GIT_ROOT} ]; then
		echo "GIT_ROOT:${GIT_ROOT} not found."
	else
		if [ ! -f ${GIT_ROOT}/.rc/rc ]; then
			if [[ ${GIT_ROOT} =~ ${USER} ]]; then
				echo "rc spec not found. Generating defaults."
				if [ ! -d ${GIT_ROOT}/.rc -a -w ${GIT_ROOT} ]; then
					mkdir ${GIT_ROOT}/.rc
				fi
				if [ ! -f ${GIT_ROOT}/.rc/rc -a -w ${GIT_ROOT}/.rc ]; then
					cp ~/.default/rc ${GIT_ROOT}/.rc/
					mkdir ${GIT_ROOT}/.rc/tags
				fi
				rc_spec=${GIT_ROOT}/.rc/rc
			else
				echo "rc spec not found. Using defaults."
				rc_spec=~/.git_default_rc/rc
			fi
		else
			rc_spec=${GIT_ROOT}/.rc/rc
		fi
	fi
	echo "GIT_ROOT:${GIT_ROOT}"

	# Define CSCOPE database
	#if [ -f ${GIT_ROOT}/.rc/cscope/cscope.out ]; then
	#	CSCOPE_DB=${GIT_ROOT}/.rc/cscope/cscope.out
	#	export CSCOPE_DB
	#fi

	if [[ ! ${GIT_ROOT} =~ ${USER} ]]; then
		PS_COLOR=${FG_PINK}
	elif [[ $HOSTNAME =~ "bsnvdga0120" ]]; then
		PS_COLOR=${FG_ORG}
	else
		PS_COLOR=${FG_CYAN}
	fi
	PS_INFO="$GIT_REPO\$(__git_ps1)"
	TITLE_INFO="[${GIT_REPO}]"
else
	PS_COLOR=${FG_GRN}
	PS_INFO="${PS_HOST}${FG_YLW}\$(__git_ps1)${FG_RST}"
	TITLE_INFO="${USER}"
fi

# Include the default resource definitions
. ${HOME}/.default_rc

if [ ${rc_spec} ]; then
	. ${rc_spec}
	echo "RC SPEC:${rc_spec}"
	echo "TAGDIR:${TAGDIR}"
fi

#Display info
export DISPLAY

function set_prompt() {
	if [ $GIT_REPO ]; then
		if [ -f ${GIT_ROOT}/.rc/swbd ]; then
			SWBD_PATH=${GIT_ROOT}/.rc/swbd
		else
			SWBD_PATH=${HOME}/.default/swbd
		fi
		. ${SWBD_PATH}

		if [ $SWBD ]; then
			SWBD_STRING="${FG_YLW}SWBD-${SWBD:4} "
		fi
	else
		SWBD_STRING=""
	fi
	PS1="[${SWBD_STRING}${PS_COLOR}${PS_INFO}${FG_RST}] ${PS_DIR}${PS_SYMB} ";
	export PS1
}

function set_title() {
	set_prompt

	if [ $GIT_REPO ]; then
		echo -ne "\033]0;${TITLE_INFO} ${PWD}\007" | sed -e "s/\/home\/${USER}/~/" -e "s|/zzz/work[0-9][0-9]\(.*\)/.*${GIT_REPO}|\1|" -e "s|/vobs|/.|" -e "s|/projects|.|" -e "s|/springboard|.|"
	else
		echo -ne "\033]0;${TITLE_INFO} ${PWD}\007" | sed -e "s/\/home\/${USER}/~/" -e "s|/vobs|/.|" -e "s|/projects|.|" -e "s|/springboard|.|"
	fi
}

if [ $TERM = xterm ]; then
	PROMPT_COMMAND=set_title
fi

# Change title of xterm when changing dirs
#if [ $TERM = xterm ]; then
#	if [ $GIT_REPO ]; then
#		PROMPT_COMMAND='echo -ne "\033]0;${TITLE_INFO} ${PWD}\007" | sed -e "s/\/home\/${USER}/~/" -e "s|/zzz/work[0-9][0-9]\(.*\)/.*${GIT_REPO}|\1|" -e "s|/vobs|/.|" -e "s|/projects|.|" -e "s|/springboard|.|"'
#	else
#		PROMPT_COMMAND='echo -ne "\033]0;${TITLE_INFO} ${PWD}\007" | sed -e "s/\/home\/${USER}/~/" -e "s|/vobs|/.|" -e "s|/projects|.|" -e "s|/springboard|.|"'
#	fi
#fi

# cat .bash_profile 
#if [ $(date +%m%d) = "0401" ]; then
#	clear
#	echo -e "Microsoft Windows XP [Version 5.1.2600]\n(C) Copyright 1985-2001 Microsoft Corp.\n"
#	export PROMPT_COMMAND="export PS1=\$(pwd|sed 's/home[0-9][0-9]/Documents and Settings/;s/\//\\\\\\\\/g;s/^/C:/;s/$/> /')"
#fi
