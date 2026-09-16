#!/bin/bash

# Default resource file
#
# .default/common_rc.sh -	Set user specific environment options. This should include any aliases, environment path
#							variables, and any other user specific environment options.
#
# This file is sourced in the .bashrc script after defaults have been initialized but before any processing of the env
# variables or execution of supporting scripts This allows the user to override some defaults, or setup other parameters
# prior to executing further env setup scripts. This can be used in conjunction with the .default/post_rc.sh script to
# control and override environment default set in the .bashrc script on a per user basis in the event .bashrc is a common
# file.
#
# The general order of loading resource scripts is as follows:
#	.bashrc
#		// setup any bash environment and other variables
#		// initialize any common ENV vars (PATH / LD_RUN_PATH / etc)
#		// determine env specific resource script based on GIT_REPO
#		. .default/common_rc.sh		# load common_rc.sh script to set any user specific env variables
#		. ${GIT_REPO}/.rc/rc		# load env specific resource script
#		// process any ENV variables needed
#		// setup prompt / title routines
#		. .default/post_rc.sh		# load post_rc.sh script to override anything that was done so far

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
