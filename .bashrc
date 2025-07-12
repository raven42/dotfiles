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
export DISPLAY
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
export HOME_PATH=.:~/bin:~/sbin:~/bin/cron:~/.local/bin
export PATH=${HOME_PATH}:/bin:/usr/sbin:/usr/bin:/usr/local/bin:/cmd:/snap/bin
export SILENT_SOURCING=1
export TAGDIR=$HOME/.ctags
export TMOUT=0
export TZ=/usr/share/zoneinfo/US/Central
export UNIFIED_HISTORY=0
export USE_UNICODE=1
export VISUAL=vim

################################################################################
# Setup color codes
TERM_FG_BLACK="\033[0;30m"
TERM_FG_RED="\033[0;31m"
TERM_FG_GREEN="\033[0;32m"
TERM_FG_YELLOW="\033[0;33m"
TERM_FG_BLUE="\033[0;34m"
TERM_FG_MAGENTA="\033[0;35m"
TERM_FG_CYAN="\033[0;36m"
TERM_FG_WHITE="\033[0;37m"
TERM_FG_RESET="\033[0;0m"

TERM_FG_PINK="\033[38;5;212m"
TERM_FG_ORANGE="\033[38;5;202m"

################################################################################
# Setup the ECHO and SOURCE_ECHO variables
#
# This will setup the ECHO and SOURCE_ECHO variables if not an interactive shell
# (ex. SCP commands) need to do at least basic PATH setup and other common env vars
#
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

################################################################################
# Setup the XDG_CACHE_HOME directory
#
# This will setup the XDG_CACHE_HOME directory if it is not already set.
#
export XDG_CACHE_HOME=/work/${USER}/.cache
if [[ ! -d $XDG_CACHE_HOME ]]; then
	if [[ ! -d $(dirname $XDG_CACHE_HOME) ]]; then
		# Parent directory doesn't exist. Reset to $HOME
		export XDG_CACHE_HOME=$HOME/.cache
	else
		mkdir $XDG_CACHE_HOME
	fi
fi

################################################################################
# source()
# Params: <file> - File to be sourced
#
# This function will help provide a consisten means to source any resource files overriding the default built-in
function source() {
	# echo "$FUNCNAME(argc:$# argv:$@)"
	file=$1
	if [[ ! -z "$file" && -f $file ]]; then
		$SOURCE_ECHO "sourcing .. $file"
		. $file
	elif [[ ! -z "$file" ]]; then
		$SOURCE_ECHO "sourcing .. $file ${TERM_FG_RED}(NOT FOUND)${TERM_FG_RESET}"
	fi
}

################################################################################
# Source the profile.d scripts
#
# This will source the profile.d scripts that are located in the /etc/profile.d
# directory as well as the completions directory in the $HOME/bin/completions
# directory.
#
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

################################################################################
# Setup the directory colors
#
# This will setup the directory colors for ls, etc. Prefer ~/.dir_colors
#
if [[ -f ${HOME}/.dircolors ]]; then
	eval `dircolors -b ${HOME}/.dircolors`
elif [[ -f /etc/DIR_COLORS ]]; then
	eval `dircolors -b /etc/DIR_COLORS`
fi

################################################################################
# Purge any modules so we can start fresh if any were loaded
#
# This will purge any modules that were loaded so we can start fresh if any were
# loaded. This uses the `module` command to purge any modules that were loaded.
# More information can be found at: https://modules.readthedocs.io/en/stable/
#
[[ "$(command -v module)" ]] && module purge

################################################################################
# Source various other bash resource scripts to enhance our shell environment
#
# This will source various other bash resource scripts to enhance our shell
# environment.
#
source $HOME/.default/git-completion.bash	# used for git command completion
source $HOME/.default/git-prompt.sh			# used for git prompt functions used by the prompt.bash script
source $HOME/.default/change_dir.sh			# used to override the cd command to integrate with git environments
source $HOME/.default/shell_functions.bash	# misc shell functions
source $HOME/.default/pyenv.sh				# setup pyenv for python environments
source $HOME/.default/python-venv.sh		# setup python venv for python virtual environments
source $HOME/.default/vscode_rc.sh			# setup vscode environment variables and shortcuts
source $HOME/.default/common_rc.sh			# setup site specific environment variables
source $HOME/.private/private_rc.sh			# setup user private environment variables
source $HOME/.default/git-environment.bash	# should be after private_rc.sh so user settings can be applied
source $HOME/.private/aliases.sh			# setup initial aliases
source $HOME/.default/prompt.bash			# setup the user defined prompt for the shell
source $HOME/.private/post_rc.sh			# [KEEP LAST] finally source the post_rc.sh script last to override any settings
