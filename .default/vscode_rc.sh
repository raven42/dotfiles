#!/bin/bash

# This resource script is used to setup the vscode environment variables and functions.

################################################################################
# Setup the vscode environment
#
# This will ensure we have the `code` program in our PATH. This allows opening
# remote files with `code <file>`
#
if [[ -d "$HOME/.vscode-server" ]]; then
	code_latest_version=$(dirname $(find ~/.vscode-server -type f -executable -name code))
	export PATH=${code_latest_version}:$PATH
fi

################################################################################
# refresh_vscode_ipc()
#
# This is a helper routine to refresh the VSCODE_IPC_HOOK_CLI env variable. In some instances this can be left stale
# pointing to a vscode-server instance that is no longer there. When this occurs, the `code <file>` command may produce
# an error indicating an IPC sock error. Refreshing this env variable should fix the problem.
function refresh_vscode_ipc() {
	echo -n "Refreshing the VSCODE_IPC_HOOK_CLI env variable ..."
	export VSCODE_IPC_HOOK_CLI=$(lsof 2> /dev/null | grep $USER | grep vscode-ipc | awk '{print $(NF-1)}' | head -n 1)
	echo " done [$VSCODE_IPC_HOOK_CLI]."
}
alias vscode-refresh=refresh_vscode_ipc
