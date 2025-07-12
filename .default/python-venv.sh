#!/bin/bash

################################################################################
# Setup the python virtual environment if it exists

function activate_python_venv() {
    PYTHON_VENV_PATH=$PWD/.venv
    if [[ -f $PYTHON_VENV_PATH/bin/activate ]]; then
        echo "Activating Python virtual environment at $PYTHON_VENV_PATH"
        source $PYTHON_VENV_PATH/bin/activate
    fi

}

# When this file is sourced, call the main funciton
activate_python_venv