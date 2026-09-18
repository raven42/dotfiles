# Keep this local to each aliases file: these may also be sourced independently.
if declare -F change_dir >/dev/null; then
    CD=change_dir
else
    CD=cd
fi

alias vscode-refresh=refresh_vscode_ipc
