#!/bin/bash

# This script is used to setup the pyenv environment.

if [[ -d /work/${USER} ]]; then
	PYENV_ROOT=/work/${USER}/.pyenv
else
	PYENV_ROOT=${HOME}/.pyenv
fi

if [ -d $PYENV_ROOT ]; then

    export PATH=$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH

    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
fi
