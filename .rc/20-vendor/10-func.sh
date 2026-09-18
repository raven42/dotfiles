# Upstream scripts retain their filenames under a non-autoloaded directory.
source "${BASH_SOURCE[0]%/*}/scripts/git-completion.bash"
source "${BASH_SOURCE[0]%/*}/scripts/git-prompt.sh"
source "${BASH_SOURCE[0]%/*}/scripts/git-environment.sh"
source "${BASH_SOURCE[0]%/*}/scripts/vscode-ipc.sh"
