#!/bin/bash

#
# This resource script is used to setup the prompt for the shell.
#

################################################################################
# These variables are used to control the behavior of the prompt.
#
# PROMPT_COMMAND - The command to run when the prompt is displayed. This is set
# to the set_prompt function defined below.
#
# PROMPT_COMMAND_PATH - This is a directory that contains any files that should
# be sourced during the execution of PROMPT_COMAMND. This allows for updating
# env variables on each command if needed, or adjusting the information displayed
# in the prompt. To add a resource script to the prompt command path, just put
# the <file>.sh script in this directory
#
# SHOW_TARGET_IN_PROMPT - Controls whether the target is shown in the prompt.
#   0: Do not show the target in the prompt
#   1: Show the target in the prompt
#
# SRC_PATH_PREFIX - This is the prefix to use for the source path. This is used
# to shorten the path in the terminal title.
# Example: SRC_PATH_PREFIX="common/path/to/src" will result in truncating that
# portion out of the window path title. So if for example you were in the path
#     /<repo>/common/path/to/src/lib/
# then the window title would show
#     /<repo>/../lib/
#
export SRC_PATH_PREFIX="projects"
export PROMPT_COMMAND=set_prompt
export PROMPT_COMMAND_PATH=$HOME/bin/prompt_command
export SHOW_TARGET_IN_PROMPT=1
export SRC_PATH_PREFIX="projects"

################################################################################
# Setup the color codes
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

################################################################################
# format_prompt()
#
# This function will format the prompt.
#
function format_prompt() {
	# The prompt is set by exporting the PS1 variable with any string
	if [ $SHOW_TARGET_IN_PROMPT -eq 1 -a "$BLD_TARGET" != "" ]; then
		TARGET_STRING="${FG_YELLOW}${BLD_TARGET}${FG_RESET} "
	else
		TARGET_STRING=""
	fi

    if [[ $(command -v git_prompt_format) ]]; then
		export PS1="${PROMPT_PREFIX}${TARGET_STRING}$(git_prompt_format) ${PS_DIR}${PS_SYMB} "
	else
		export PS1="${PROMPT_PREFIX}${TARGET_STRING} ${PS_DIR}${PS_SYMB} "
	fi
}

################################################################################
# format_title()
#
# This function will format the title.
#
function format_title() {
    if [[ $(command -v git_title_format) ]]; then
		echo -ne "\033]0;${PWD} $(git_title_format)\007" | sed -e "s|/home/${USER}|~|" -e "s|/work/${USER}||" -e "s|${SRC_PATH_PREFIX}|..|"
	else
		echo -ne "\033]0;${PWD}\007" | sed -e "s|/home/${USER}|~|" -e "s|/work/${USER}||" -e "s|${SRC_PATH_PREFIX}|..|"
	fi
}

################################################################################
# set_prompt()
#
# This function will set the prompt.
#
function set_prompt() {
	# The following history commands allow us to track the history across different
	# sessions and log them all to the same file
	if [ $UNIFIED_HISTORY -eq 1 ]; then
		history -a	# write current history to the history file
		history -c	# clear current in memory history
		history -r	# read from history file into memory
	fi

	if [ -d $PROMPT_COMMAND_PATH ]; then
		for i in ${PROMPT_COMMAND_PATH}/*.sh; do
			if [ -r "$i" ]; then
				. $i
			fi
		done
		unset i
	fi

	format_prompt
	format_title
}
