#!/bin/bash
# Reference variable settings: copy the entries you need into a tier's 00-vars.sh.
# Actual tier layout: 00-vars.sh, 10-func.sh, 20-env.sh, 50-aliases.sh, 90-post.sh.
# templates/ is not auto-loaded. Keep side effects and PATH changes in 20-env.sh.

# To disable unicode characters in VIM and bash prompts. There are unicode characters used for the terminal window title,
# and in VIM, unicode characters are used in the status line, buffer line, and window title.
export USE_UNICODE=1

# Set autosave option for vim
export AUTOSAVE=0

# Setting this to 0 will not show the current $BLD_TARGET in the command prompt. By default the prompt will look like this:
#   $BLD_TARGET $GIT_REPO (<git-branch>) <directory>$ 
# Setting this to 0 will result in the following:
#   $GIT_REPO (<git-branch>) <directory>$
export SHOW_TARGET_IN_PROMPT=1

# This env variable is used by the .vimrc to shorten path names for window title
# Example: SRC_PATH_PREFIX="common/path/to/src" will result in truncating that
# portion out of the window path title. So if for example you were in the path
#     /<repo>/common/path/to/src/lib/
# then the window title would show
#     /<repo>/../lib/
# This variable is also used by the retag script to generate ctags for a repository.
export SRC_PATH_PREFIX="projects"

# UNIFIED_HISTORY - This env var is used to determine if a unified history should be used between all sessions into a host.
# This will enable the 'history' command to use a file instead of in memory history so the shell history is updated every
# command across all sessions, not just the current session as is the default
export UNIFIED_HISTORY=0

# Setup source code path prefix based on GIT_ROOT, also setup TAGDIR which is used by VIM to look for any ctags
if [ $GIT_ROOT ]; then
	ROOT_PATH=${GIT_ROOT}
	if [ -d ${GIT_ROOT}/.rc/tags ]; then
		TAGDIR=${GIT_ROOT}/.rc/tags
	else
		TAGDIR=${HOME}/.default/tags
	fi
else
	TAGDIR=${HOME}/.default/tags
fi

# TAG_PATH - The TAG_PATH variable defines a list of paths to parse for the retag script. This is
# a whitespace delimited list of path definitions. Each path definition is a colon delimited list
# consisting of <default>:<tag-file>:<path> with the following definitions:
#     <default> - 0|1  if 0, then only process this path if the retag -a option is given
#     <tag-file> - The filename to use for the output
#     <path> - The path to start a recursive tag search in
# This is all run from the ${GIT_ROOT}/${SRC_PATH_PREFIX} location. All paths should be
# relative from that directory
TAG_PATH="1:tags_src:src"
TAG_PATH="$TAG_PATH 1:tags_inc:inc"
export TAG_PATH

# Set defaults needed for ~/sbin/git-repo script to work with our environment
export WORKSPACES=${HOME}/work:${HOME}/projects
export WORKSPACE_SEARCH_DEPTH=5
export DEFAULT_GIT_SERVER=git@github.com
