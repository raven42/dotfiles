#!/bin/bash

function change_dir()
{
	local stack_dir new_dir idx_dir idx
	local -i cnt stack_size
	local stack_limit=10

	if [[ $1 ==  "--" ]]; then
		dirs -l -v
		return 0
	fi

	new_dir=$1
	[[ -z $1 ]] && new_dir=$HOME

	if [[ ${new_dir:0:1} == '-' ]]; then
		# Extract dir N from dirs
		idx=${new_dir:1}
		[[ -z $idx ]] && idx=1
		idx_dir=$(dirs +$idx | awk '{ print $2 }')
		[[ -z $idx_dir ]] && return 1
		new_dir=$idx_dir
	fi

	# '~' has to be substituted by ${HOME}
	[[ ${new_dir:0:1} == '~' ]] && new_dir="${HOME}${new_dir:1}"

	# Now change to the new dir and add to the top of the stack
	pushd "${new_dir}" > /dev/null || return 1
	new_dir=$(pwd)

	# Remove any other occurence of this dir, skipping the top of the stack
	cnt=1
	stack_size=$(dirs -p 2>/dev/null | wc -l)
	while [[ $cnt -lt ${stack_size} ]]; do
		stack_dir=$(dirs -l +${cnt} 2>/dev/null | awk '{ print $2 }') || return 0
		if [[ "${stack_dir}" == "${new_dir}" ]]; then
			popd -n +$cnt 2>/dev/null 1>/dev/null
			stack_size=$((stack_size - 1))
			continue
		fi
		if [[ ${cnt} -ge ${stack_limit} ]]; then
			popd -n +$cnt 1>/dev/null 2>/dev/null
			stack_size=$((stack_size - 1))
			continue
		fi
		cnt=$((cnt + 1))
	done

	# If we have the update_git_environment function in the shell, then call it when we change directories
	[[ $(type -t update_git_environment) == function ]] && update_git_environment

	return 0
}

# Create alias for `cd` command
alias cd=change_dir
