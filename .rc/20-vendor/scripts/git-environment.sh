#!/usr/bin/env bash
#
# Copyright (c) 2023 David Hegland <david.hegland@broadcom.com>
#
# This shell environment resource file will help track various paths and such based on the active repository and
# any submodules. This will also display a message when entering / leaving a git repository by default. This can
# be disabled by setting the $GIT_ENVIRONMENT_SILENT=1
#
# The following environment variables will be set:
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
		echo "  BLD_TARGET:$BLD_TARGET"
		echo ""
	fi
}

function git_title_format() {
	if [[ ! -z "$GIT_REPO" && "$USE_UNICODE_TITLE" == "1" ]]; then
		GIT_TITLE_INFO="\xee\x82\xa0$(__git_ps1)"
	elif [[ ! -z "$GIT_REPO" ]]; then
		GIT_TITLE_INFO="$(__git_ps1)"
	else
		GIT_TITLE_INFO="$USER"
	fi
	printf '%b' "$GIT_TITLE_INFO"
}

function git_prompt_format() {
	if [ $GIT_REPO ]; then
		# branch code $'\xee\x82\xa0'
		GIT_PS_INFO="${FG_ORANGE}${GIT_REPO}${FG_MAGENTA}\$(__git_ps1)${FG_RESET}"
		# PS_INFO=$'$GIT_REPO \xee\x82\xa0$(__git_ps1)'
	else
		GIT_PS_INFO="${FG_GREEN}${PS_HOST}${FG_YELLOW}${FG_MAGENTA}\$(__git_ps1)${FG_RESET}"
	fi
	printf '%s' "$GIT_PS_INFO"
}

function update_git_environment() {
	local ECHO=$ECHO
	local previous_git_root=${GIT_ROOT:-}
	[[ $GIT_ENVIRONMENT_SILENT != 1 ]] || ECHO=:
	_print_git_env "PRE"
	# Save off the current $GIT_DIR so it can be checked later. We need to `unset` it to avoid git using
	# the cached value and force it to recompute the rev-parse so we can properly determine if the directory
	# change has caused a change in the GIT_REPO
	# unset GIT_WORK_TREE

	# Recalculate the git_toplevel and git_superproject
	git_toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
	git_repository=$(basename "$git_toplevel" 2>/dev/null)
	git_superproject=$(git rev-parse --show-superproject-working-tree 2>/dev/null)
	git_remote=$(git config --get remote.origin.url 2>/dev/null)

	_print_git_env "PRE-CHECK"

	if [[ -z "$git_superproject" && ! -z "$git_toplevel" && "$git_toplevel" != "${GIT_PATH:+$GIT_PATH/}$GIT_REPO" ]]; then
		# We have entered a directory that is not a submodule and is different than our previous GIT_ROOT
		export GIT_ROOT=$git_toplevel
		export GIT_REPO=$(basename "$GIT_ROOT")
		export GIT_PATH=$(dirname "$GIT_ROOT")
		export GIT_REMOTE=$(echo $git_remote | sed -e 's|.*:||' -e 's|\.git||')
		unset GIT_SUPERPROJECT
		$ECHO "Entering main repository .. [$GIT_ROOT $GIT_REPO@$GIT_REMOTE]"
	elif [[ ! -z "$git_superproject" && "$git_superproject" != "$GIT_SUPERPROJECT" ]]; then
		# We have entered a direcotry that is a submodule, and has a different superproject
		export GIT_ROOT=$git_superproject
		export GIT_REPO=$(basename "$git_toplevel")
		export GIT_PATH=$(dirname "$git_toplevel")
		export GIT_REMOTE=$(echo $git_remote | sed -e 's|.*:||' -e 's|\.git||')
		export GIT_SUPERPROJECT=$GIT_ROOT
		$ECHO "Entering sub-module repository .. [$GIT_ROOT $GIT_REPO@$GIT_REMOTE]"
	elif [[ ! -z "$git_superproject" && "$git_toplevel" != "${GIT_PATH:+$GIT_PATH/}$GIT_REPO" ]]; then
		# We have entered a direcotry that is a submodule, and has a different superproject
		export GIT_ROOT=$git_superproject
		export GIT_REPO=$(basename "$git_toplevel")
		export GIT_PATH=$(dirname "$git_toplevel")
		export GIT_REMOTE=$(echo $git_remote | sed -e 's|.*:||' -e 's|\.git||')
		export GIT_SUPERPROJECT=$GIT_ROOT
		$ECHO "Entering sub-module repository .. [$GIT_ROOT $GIT_REPO@$GIT_REMOTE]"
	# elif [[ "$(pwd)" == "$HOME" ]]; then
	# 	# We have entered the main githome repository
	# 	export GIT_ROOT=$HOME
	# 	export GIT_REPO="githome"
	# 	export GIT_PATH=$(dirname "$GIT_ROOT")
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

	# Notify listeners after the new Git context has been exported.
	if [[ ${__RC_LOADING:-0} != 1 ]]; then
		rc_emit git_environment_changed "$previous_git_root" "${GIT_ROOT:-}" || :
	fi

	_print_git_env "POST"
}
