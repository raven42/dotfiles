# Vendor defaults; safe to re-source on directory changes.
export GIT_ENVIRONMENT_DEBUG="${GIT_ENVIRONMENT_DEBUG:-0}"
export GIT_ENVIRONMENT_INTEGRATION="${GIT_ENVIRONMENT_INTEGRATION:-1}"
export VSCODE_INSTALL_PATH="${VSCODE_INSTALL_PATH:-$HOME/.vscode-server}"
export NODE_OPTIONS="${NODE_OPTIONS:---max-old-space-size=16384}"
