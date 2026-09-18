#
# Basic bash environment exports (history, locale, misc tool config), the ~/.rc extension-point layout
# ($RC_PATH, $PROMPT_COMMAND_PATH), and shared terminal color codes / PS1 escape-sequence shorthands used by
# both the prompt-formatting functions here in 00-core and by git_prompt_format()/git_title_format() in
# 20-vendor/git-environment.sh (previously defined identically in both .bashrc and git-environment.bash;
# consolidated here so there's one copy instead of two that could drift out of sync).
#
# $RC_PATH itself can't be used to bootstrap the tier-loading loop in .bashrc that finds *this* file in the
# first place -- that loop hardcodes $HOME/.rc instead. This export is for everything else that runs later
# (aliases, functions, _which()) and can just reference $RC_PATH by name.
#

export AUTOSAVE="${AUTOSAVE-0}"
export EDITOR="${EDITOR-vim}"
export HISTTIMEFORMAT="${HISTTIMEFORMAT-%m/%d/%Y-%T }"
export HISTCONTROL="${HISTCONTROL-ignoredups}"
export HISTFILE="${HISTFILE-$HOME/.history-$HOSTNAME}"
export HISTIGNORE="${HISTIGNORE-pwd:ls:ls -al:ll:history:h:h[dh]:h [0-9]*:h[dh] [0-9]*}"
export HISTSIZE="${HISTSIZE-5000}"
export HISTFILESIZE="${HISTFILESIZE-999999}"
export LANG="${LANG-en_US.UTF-8}"
export LANGUAGE="${LANGUAGE-en_US.UTF-8}"
export LC_ALL="${LC_ALL-en_US.UTF-8}"
export LYNX_CFG="${LYNX_CFG-$HOME/.lynxrc}"
export MAKEFLAGS="${MAKEFLAGS--s}"
export MANPATH="${MANPATH-}"
export PATH="${PATH-/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin}"
export PROMPT_PREFIX="${PROMPT_PREFIX-}"
export PYTHONPATH="${PYTHONPATH-}"
export TAGDIR=$HOME/.ctags
export TMOUT="${TMOUT-0}"
export TZ="${TZ-/usr/share/zoneinfo/US/Central}"
export USE_UNICODE_TITLE="${USE_UNICODE_TITLE-0}"
export VISUAL="${VISUAL-vim}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"

# To disable unicode characters in VIM and bash prompts. There are unicode characters used for the terminal window title,
# and in VIM, unicode characters are used in the status line, buffer line, and window title.
export USE_UNICODE="${USE_UNICODE-1}"

# Setting this to 0 will not show the current $BLD_TARGET in the command prompt. By default the prompt will look like this:
#   $BLD_TARGET $GIT_REPO (<git-branch>) <directory>$
# Setting this to 0 will result in the following:
#   $GIT_REPO (<git-branch>) <directory>$
export SHOW_TARGET_IN_PROMPT="${SHOW_TARGET_IN_PROMPT-1}"

# UNIFIED_HISTORY - This env var is used to determine if a unified history should be used between all sessions into a host.
# This will enable the 'history' command to use a file instead of in memory history so the shell history is updated every
# command across all sessions, not just the current session as is the default
export UNIFIED_HISTORY="${UNIFIED_HISTORY-0}"

export RC_PATH=$HOME/.rc
export PROMPT_COMMAND_PATH=$RC_PATH/prompt.d

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

# Safe defaults allow later tiers to load even without 10-profile.
export RC_PROFILE_PATH="$RC_PATH/10-profile"
export RC_PROFILE="${RC_PROFILE:-default}"
export RC_AUTO_VENV="${RC_AUTO_VENV:-1}"
export VIRTUAL_ENV_DISABLE_PROMPT="${VIRTUAL_ENV_DISABLE_PROMPT:-1}"
export SRC_PATH_PREFIX="${SRC_PATH_PREFIX-}"
export WORKSPACES="${WORKSPACES:-$HOME/Projects}"
export WORKSPACE_SEARCH_DEPTH="${WORKSPACE_SEARCH_DEPTH:-2}"
export DEFAULT_GIT_SERVER="${DEFAULT_GIT_SERVER:-git@github.com}"
export DEFAULT_GIT_REPO="${DEFAULT_GIT_REPO:-raven42/dotfiles.git}"
export WORK_PATH="${WORK_PATH:-/work/$USER}"
export BLD_TARGET="${BLD_TARGET-}"
export TAG_PATH="${TAG_PATH-}"
if [[ -n $GIT_ROOT ]]; then
    if [[ -d $GIT_ROOT/.rc/tags ]]; then
        export TAGDIR="$GIT_ROOT/.rc/tags"
    else
        export TAGDIR="$GIT_ROOT/.ctags"
    fi
fi
