#!/usr/bin/env bash

shopt -s checkwinsize

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
# GNU coreutils may expose this as gdircolors on macOS. BSD ls needs neither.
_dircolors_command=
if command -v dircolors >/dev/null 2>&1; then
	_dircolors_command=dircolors
elif command -v gdircolors >/dev/null 2>&1; then
	_dircolors_command=gdircolors
fi
if [[ -n $_dircolors_command ]]; then
	if [[ -f $DIRCOLORS ]]; then
		eval "$("$_dircolors_command" -b "$DIRCOLORS")"
	elif [[ -f /etc/DIR_COLORS ]]; then
		eval "$("$_dircolors_command" -b /etc/DIR_COLORS)"
	fi
fi
unset _dircolors_command

################################################################################
# Display info
export DISPLAY

path_prepend PATH "${HOME}/sbin"
path_prepend PATH "${HOME}/bin"
path_prepend PATH "${HOME}/bin/cron"
path_prepend PATH "${HOME}/.local/bin"
path_prepend PATH "${HOME}/bin/lbin"
path_prepend PATH .

# Preserve inherited PATH (including a remote VS Code CLI and active virtualenv).
path_append MANPATH "$HOME/local/man"
# A trailing empty field asks man to retain its system search path.
case "$MANPATH" in *:) ;; *) export MANPATH="$MANPATH:" ;; esac

# Core plugin: automatic project virtualenv selection.
rc_on change_dir rc_update_venv
rc_on shell_ready rc_update_venv

# Refresh tier variables when a repository-context provider reports a change.
rc_on git_environment_changed __rc_refresh_vars
