#/usr/bin/env bash

# This file provides some basic path manipulation functions to append / prepend to environment variables such as the
# $PATH or $MANPATH environment variables.

path_append() {
    variable=$1
    value=$2
    if [ -d "$value" ]; then # Check if the argument is a valid directory
        # Get current value of the variable using indirect expansion
        current_value="${!variable}"
        if [[ ":$current_value:" != *":$value:"* ]]; then # Check if the directory is already in the variable
            # Update the variable, handling empty values
            printf -v "$variable" "%s" "${current_value:+${current_value}:}$value"
        fi
    fi
}

path_prepend() {
    variable=$1
    value=$2
    if [ -d "$value" ]; then # Check if the argument is a valid directory
        # Get current value of the variable using indirect expansion
        current_value="${!variable}"
        if [[ ":$current_value:" != *":$value:"* ]]; then # Check if the directory is already in the variable
            # Update the variable, handling empty values
            printf -v "$variable" "%s" "$value${current_value:+:$current_value}"
        fi
    fi
}

path_remove() {
    variable=$1
    value=$2
    # Get current value of the variable using indirect expansion
    current_value="${!variable}"
    if [[ ":$current_value:" == *":$value:"* ]]; then # Check if the directory is in the variable
        # Remove the value from the path
        # Handle case where value is at the beginning
        current_value="${current_value/#$value:/}"
        # Handle case where value is at the end
        current_value="${current_value/%:$value/}"
        # Handle case where value is in the middle
        current_value="${current_value//:$value:/:}"
        # Handle case where value is the only entry
        if [[ "$current_value" == "$value" ]]; then
            current_value=""
        fi
        # Update the variable
        printf -v "$variable" "%s" "$current_value"
    fi
}