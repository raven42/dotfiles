#
# vscode_env.bash
#
# Setup various bash environment variables and such for our shell
#

################################################################################
# vscode:
# This will ensure we have the `code` program in our PATH. This allows opening remote files with `code <file>`
VCF_INSTALL_PATH="/work/$USER/.vscode-vcf/.vscode-server/"
BCP_INSTALL_PATH="$HOME/.vscode-server/"
if [[ -d $VCF_INSTALL_PATH ]]; then
	code_latest_version=$(dirname $(ls -tra -1 $(find $VCF_INSTALL_PATH -name code) | sed -n '2p'))
elif [[ -d $BCP_INSTALL_PATH ]]; then
	code_latest_version=$(dirname $(ls -tra -1 $(find $BCP_INSTALL_PATH -name code) | sed -n '2p'))
fi
export PATH=${code_latest_version}:$PATH
export NODE_OPTIONS="--max-old-space-size=16384"

################################################################################
# refresh_vscode_ipc()
#
# This is a helper routine to refresh the VSCODE_IPC_HOOK_CLI env variable. In some instances this can be left stale
# pointing to a vscode-server instance that is no longer there. When this occurs, the `code <file>` command may produce
# an error indicating an IPC sock error. Refreshing this env variable should fix the problem.
function refresh_vscode_ipc() {
	echo -n "Refreshing the VSCODE_IPC_HOOK_CLI env variable ..."
	export VSCODE_IPC_HOOK_CLI=$(lsof -u $(id -u) 2> /dev/null | grep vscode-ipc | awk '{print $(NF-1)}' | head -n 1)
	echo " done [$VSCODE_IPC_HOOK_CLI]."
}
alias vscode-refresh=refresh_vscode_ipc
