#!/usr/bin/env bash

shopt -s checkwinsize

# Setup and refresh the XDG_CACHE_HOME directory if needed
if [[ ! -d $XDG_CACHE_HOME ]]; then
	if [[ ! -d $(dirname $XDG_CACHE_HOME) ]]; then
		# Parent directory doesn't exist. Reset to $HOME
		export XDG_CACHE_HOME=$HOME/.cache
	else
		mkdir $XDG_CACHE_HOME
	fi
fi

################################################################################
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

DIRCOLORS=${HOME}/.dircolors
if [[ -f ${DIRCOLORS} ]]; then
	eval `dircolors -b ${DIRCOLORS}`
elif [[ -f /etc/DIR_COLORS ]]; then
	eval `dircolors -b /etc/DIR_COLORS`
fi

################################################################################
# Display info
export DISPLAY