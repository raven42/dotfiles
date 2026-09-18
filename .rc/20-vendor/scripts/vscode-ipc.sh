#
# vscode_env.bash
#
# Setup various bash environment variables and such for our shell
#

################################################################################
# vscode:
# This will ensure we have the `code` program in our PATH. This allows opening remote files with `code <file>`
# Keep the CLI supplied by an existing terminal/Remote SSH session.
# Otherwise find the desktop macOS CLI or the newest installed remote CLI.
__vscode_setup_path() {
	command -v code >/dev/null 2>&1 && return 0
	local candidate latest=
	if [[ $OSTYPE == darwin* ]]; then
		for candidate in "$HOME/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" \
			"/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"; do
			if [[ -x $candidate ]]; then
				export PATH="${candidate%/*}:$PATH"
				return 0
			fi
		done
	fi
	if [[ -d $VSCODE_INSTALL_PATH ]]; then
		while IFS= read -r -d '' candidate; do
			[[ -x $candidate ]] || continue
			if [[ -z $latest || $candidate -nt $latest ]]; then
				latest=$candidate
			fi
		done < <(find "$VSCODE_INSTALL_PATH" -type f -path '*/bin/*' -name code -print0 2>/dev/null)
		if [[ -n $latest ]]; then
			export PATH="${latest%/*}:$PATH"
		fi
	fi
	return 0
}


################################################################################
# refresh_vscode_ipc()
#
# This is a helper routine to refresh the VSCODE_IPC_HOOK_CLI env variable. In some instances this can be left stale
# pointing to a vscode-server instance that is no longer there. When this occurs, the `code <file>` command may produce
# an error indicating an IPC sock error. Refreshing this env variable should fix the problem.
#
# This is relatively expensive since it invokes `code --status` (spawns Node) once per candidate socket found in
# /run/user/$(id -u)/, so it should not be called unconditionally on every prompt. Pass -q to suppress output, which
# is used by the automatic PROMPT_COMMAND check in $PROMPT_COMMAND_PATH/30-vscode-ipc-check.sh.
function refresh_vscode_ipc() {
	local quiet=0
	if [[ "$1" == "-q" ]]; then
		quiet=1
	fi
	[[ $quiet -eq 0 ]] && echo -n "Refreshing the VSCODE_IPC_HOOK_CLI env variable ..."
	local sock
	for sock in $(command ls -t /run/user/$(id -u)/vscode-ipc-*.sock 2> /dev/null); do
		if VSCODE_IPC_HOOK_CLI="$sock" code --status > /dev/null 2>&1; then
			export VSCODE_IPC_HOOK_CLI="$sock"
			[[ $quiet -eq 0 ]] && echo " done [$VSCODE_IPC_HOOK_CLI]."
			return 0
		fi
	done
	[[ $quiet -eq 0 ]] && echo " failed: no live VS Code IPC socket found."
	return 1
}


################################################################################
# __vscode_ipc_is_live()
#
# Cheap liveness probe for VSCODE_IPC_HOOK_CLI, meant to run on every prompt. Unlike `code --status` (which spawns
# Node and is too slow to run unconditionally), `nc -Uz` just attempts a zero-I/O connect to the unix socket and
# returns almost instantly (~2-4ms measured), correctly distinguishing a live listener from an orphaned socket file
# left behind by a closed vscode-server.
function __vscode_ipc_is_live() {
	[[ -n "$VSCODE_IPC_HOOK_CLI" ]] && command nc -Uz "$VSCODE_IPC_HOOK_CLI" 2> /dev/null
}
