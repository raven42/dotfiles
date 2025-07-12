#!/bin/bash

#
# This file is sourced in the .bashrc script after defaults have been initialized. It adds in various shell functions
#


# Add a better `which` command that will not only find aliases, but
# will also attempt to locate where those aliases are located
function _which() {
	cmd=$1
	echo "$(type -f $cmd)"
	search_files="${HOME}/.bashrc ${HOME}/.default/common_rc.sh ${HOME}/.private/private_rc.sh ${HOME}/.private/post_rc.sh ${HOME}/.private/aliases.sh"
	if [[ "$(type -t $cmd)" =~ "alias" ]]; then
		grep_result=$(grep "alias\s\+$cmd=" $search_files 2>/dev/null)
		if [[ ! -z "$grep_result" ]]; then
			while read -r line; do
				echo "   $line"
			done <<< "$grep_result"
		fi
	fi
}
alias which=_which

# Update the dotfiles repository
function _update_dotfiles() {
	githome="git --git-dir $HOME/.cfg/ --work-tree $HOME"
	common_rc=/projects/bsnsweng/dh404494/vdi_setup/common_rc.sh
	user_common_rc=$HOME/.default/common_rc.sh

	if [[ ! -z "${GIT_ROOT}" ]]; then
		echo ""
		echo "Error: Cannot run this from within a GIT-REPO context. Please"
		echo "run this from a default shell instance."
		echo ""
		return
	fi

	echo ""
	echo "This process will update the GITHOME repository attempting to save"
	echo "any local changes. As this is a git repository, it will stash the"
	echo "changes (if found), pull anything new, then attempt to restore "
	echo "those changes."
	echo ""
	read -p "Do you wish to proceed y/n? " cont

	if [[ "$cont" != "y" ]]; then
		echo "Aborting update."
		return
	fi

	stashed=0
	if [[ $($githome status -s) != "" ]]; then
		echo "Stashing local changes..."
		$githome stash
		stashed=1
	fi

	echo "Pulling latest and updating dotfiles repository..."
	$githome pull
	$githome submodule update

	if [[ $stashed -ne 0 ]]; then
		echo "Restoring stashed changes..."
		$githome stash pop
	fi

	# Don't update for dh404494 as I own this and so it points to the same file
	if [[ "$USER" != "dh404494" ]]; then
		echo "Copying common_rc.sh file..."
		if [[ -f $user_common_rc ]]; then
			echo "Backing up current common_rc.sh at [$user_common_rc.bak]..."
			cp $user_common_rc $user_common_rc.bak
		fi
		cp $common_rc $user_common_rc
	fi

	echo "Update complete."
	echo ""

	source $HOME/.bashrc
}
alias githome-update=_update_dotfiles
