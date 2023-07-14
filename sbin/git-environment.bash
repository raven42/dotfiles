#!/bin/bash

#
# This shell environment resource file will help track various paths and such based on the active repository and
# any submodules. The following environment variables will be set:
#
#   GIT_ROOT:
#       This always points to the top most repository root. Even when inside a sub-module. This value will be
#       unset if not in a valid git repository.
#
#   GIT_REPO:
#       The repository name of the active repository. Changes as the active repository changes. This will
#       point to the repository name of the sub-module if entering a sub-module of another repository. This
#       value will be unset if not in a valid git repository.
#
#   GIT_PATH:
#       The directory where the current GIT_REPO repository is located. This value will be unset if not in a valid
#       git repository.
#
#   GIT_SUPERPROJECT:
#       Only valid if within a sub-module of another repository. This will be set to the root path of the parent
#       repository. Note: If there are multiple nested sub-modules, it will only point one repository up. This
#       value will be unset if not in a submodule.
#
#	GIT_REMOTE:
#		This will be the repository name of the remote.
#
#	XXX: DON'T TOUCH $GIT_DIR!!! Other programs use this and so it should be left to operate on it's own according
#		 to how git normally manages this.
#

# These files need to be sourced again when we change a directory incase any aliases have changed.
export GIT_ENVIRONMENT_DEBUG=0
export GIT_ENVIRONMENT_INTEGRATION=1

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

if [ -z "$PS1" ]; then
	ECHO=:
else
	ECHO='echo -e'
fi

function update_external_environment() {
	# Other environment variable settings
	export GIT_RC_PATH="$GIT_ROOT/.rc"

	if [[ $GITRC_ENVIRONMENT == 1 && ! -z "$GIT_REPO" ]]; then
		export BLD_TARGET_SCRIPT=$GIT_RC_PATH/bld_target.sh
	else
		export BLD_TARGET_SCRIPT=$PRIVATE_RC_PATH/bld_target.sh
	fi
}

function souce_resouce_files() {
	RESOURCE_FILES="$HOME/.private/aliases.sh:$HOME/.aliases:$GIT_ROOT/.rc/rc"

	# After we've updated any environment variables, we should source our resource files again to update any aliases
	resource_files=$(echo $RESOURCE_FILES | tr ':' '\n')
	for resource_file in $resource_files; do
		source $resource_file
	done
}

function _print_git_env() {
	if [[ $GIT_ENVIRONMENT_DEBUG > 0 ]]; then
		state=$1
		echo ""
		echo "$state: CWD:$(pwd) git_repository:$git_repository git_toplevel:$git_toplevel superproject:$git_superproject git_remote:$git_remote"
		echo "  GIT_ROOT:$GIT_ROOT"
		echo "  GIT_REPO:$GIT_REPO"
		echo "  GIT_DIR:$GIT_DIR"
		echo "  GIT_PATH:$GIT_PATH"
		echo "  GIT_REMOTE:$GIT_REMOTE"
		echo "  GIT_SUPERPROJECT:$GIT_SUPERPROJECT"
		echo "  GIT_WORK_TREE:$GIT_WORK_TREE"
		echo "  BLD_TARGET_SCRIPT:$BLD_TARGET_SCRIPT"
		echo "  BLD_TARGET:$BLD_TARGET"
		echo ""
	fi
}

function git_title_format() {
	if [[ ! -z "$GIT_REPO" && ! -z "$USE_UNICODE" ]]; then
		GIT_TITLE_INFO="\xee\x82\xa0$(__git_ps1)"
	elif [[ ! -z "$GIT_REPO" ]]; then
		GIT_TITLE_INFO="$(__git_ps1)"
	else
		GIT_TITLE_INFO="$USER"
	fi
	printf -- "$GIT_TITLE_INFO"
}

function git_prompt_format() {
	if [ $GIT_REPO ]; then
		# branch code $'\xee\x82\xa0'
		GIT_PS_INFO="${FG_ORANGE}${GIT_REPO}\$(__git_ps1)${FG_RESET}"
		# PS_INFO=$'$GIT_REPO \xee\x82\xa0$(__git_ps1)'
	else
		GIT_PS_INFO="${FG_GREEN}${PS_HOST}${FG_YELLOW}\$(__git_ps1)${FG_RESET}"
	fi
	printf -- "$GIT_PS_INFO"
}

function update_git_environment() {
	_print_git_env "PRE"
	# Save off the current $GIT_DIR so it can be checked later. We need to `unset` it to avoid git using
	# the cached value and force it to recompute the rev-parse so we can properly determine if the directory
	# change has caused a change in the GIT_REPO
	# unset GIT_WORK_TREE

	# Recalculate the git_toplevel and git_superproject
	git_toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
	git_repository=$(basename $git_toplevel 2>/dev/null)
	git_superproject=$(git rev-parse --show-superproject-working-tree 2>/dev/null)
	git_remote=$(git config --get remote.origin.url 2>/dev/null)

	_print_git_env "PRE-CHECK"

	if [[ -z "$git_superproject" && ! -z "$git_toplevel" && "$git_repository" != "$GIT_REPO" ]]; then
		# We have entered a directory that is not a submodule and is different than our previous GIT_ROOT
		export GIT_ROOT=$git_toplevel
		export GIT_REPO=$(basename $GIT_ROOT)
		export GIT_PATH=$(dirname $GIT_ROOT)
		export GIT_REMOTE=$(echo $git_remote | sed -e 's|.*:||' -e 's|\.git||')
		unset GIT_SUPERPROJECT
		$ECHO "Entering main repository .. [$GIT_ROOT $GIT_REPO@$GIT_REMOTE]"
	elif [[ ! -z "$git_superproject" && "$git_superproject" != "$GIT_SUPERPROJECT" ]]; then
		# We have entered a direcotry that is a submodule, and has a different superproject
		export GIT_ROOT=$git_superproject
		export GIT_REPO=$(basename $git_toplevel)
		export GIT_PATH=$(dirname $git_toplevel)
		export GIT_REMOTE=$(echo $git_remote | sed -e 's|.*:||' -e 's|\.git||')
		export GIT_SUPERPROJECT=$GIT_ROOT
		$ECHO "Entering sub-module repository .. [$GIT_ROOT $GIT_REPO@$GIT_REMOTE]"
	# elif [[ "$(pwd)" == "$HOME" ]]; then
	# 	# We have entered the main githome repository
	# 	export GIT_ROOT=$HOME
	# 	export GIT_REPO="githome"
	# 	export GIT_PATH=$(dirname $GIT_ROOT)
	# 	export GIT_WORK_TREE=$HOME
	# 	$ECHO "Entering githome repository .. [$GIT_ROOT $GIT_REPO@$GIT_REMOTE]"
	elif [[ -z "$git_toplevel" && ! -z "$GIT_ROOT" ]]; then
		$ECHO "Leaving repository .. [$GIT_ROOT $GIT_REPO@$GIT_REMOTE]"
		unset GIT_ROOT
		unset GIT_REPO
		unset GIT_PATH
		unset GIT_REMOTE
		unset GIT_SUPERPROJECT
	else
		# No change
		_print_git_env "NO-OP"
		return
	fi

	update_external_environment
	[[ $(type -t initialize_git_repository) == function ]] && initialize_git_repository $GIT_RC_PATH $GIT_ROOT/.rc/rc
	souce_resouce_files

	_print_git_env "POST"
}

# When this file is sourced, call the main funciton
update_git_environment
update_external_environment

_print_git_env "INIT-DONE"