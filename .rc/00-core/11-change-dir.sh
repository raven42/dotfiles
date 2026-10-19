#!/usr/bin/env bash

################################################################################
# change_dir()
#
# A `cd` replacement that maintains a directory stack (via pushd/popd), supports `cd -N` to jump to the Nth
# stack entry, and `cd --` to list the stack. A leading '-' followed by anything other than digits (e.g.
# `cd -foo`) is treated as a literal directory name; use `cd -- -1` for a directory named like a stack index.
# Emits change_dir after a successful change, passing the previous and current directory to registered callbacks.
function change_dir()
{
	local stack_dir new_dir idx_dir idx old_dir=$PWD
	local -i cnt stack_size
	local stack_limit=10
	local -i literal=0

	if [[ $1 == "--" ]]; then
		if [[ $# -eq 1 ]]; then
			builtin dirs -l -v
			return 0
		fi
		# `cd -- DIR`: DIR is a literal name, never a stack index
		shift
		literal=1
	fi

	new_dir=$1
	[[ -z $1 ]] && new_dir=$HOME

	if [[ $literal -eq 0 && ${new_dir:0:1} == '-' ]]; then
		idx=${new_dir:1}
		[[ -z $idx ]] && idx=1
		if [[ $idx =~ ^[0-9]+$ ]]; then
			# Extract dir N from dirs
			idx_dir=$(builtin dirs -l +"$idx" 2>/dev/null) || return 1
			[[ -z $idx_dir ]] && return 1
			new_dir=$idx_dir
		else
			# Not a stack index: a literal directory name starting with '-'
			new_dir="./${new_dir}"
		fi
	fi

	# '~' has to be substituted by ${HOME}
	[[ ${new_dir:0:1} == '~' ]] && new_dir="${HOME}${new_dir:1}"

	# Now change to the new dir and add to the top of the stack
	builtin pushd -- "${new_dir}" > /dev/null || return 1
	new_dir=$(pwd)

	# Remove any other occurence of this dir, skipping the top of the stack
	cnt=1
	stack_size=$(builtin dirs -p 2>/dev/null | wc -l)
	while [[ $cnt -lt ${stack_size} ]]; do
		stack_dir=$(builtin dirs -l +"$cnt" 2>/dev/null) || break
		if [[ "${stack_dir}" == "${new_dir}" ]]; then
			builtin popd -n +$cnt 2>/dev/null 1>/dev/null
			stack_size=$((stack_size - 1))
			continue
		fi
		if [[ ${cnt} -ge ${stack_limit} ]]; then
			builtin popd -n +$cnt 1>/dev/null 2>/dev/null
			stack_size=$((stack_size - 1))
			continue
		fi
		cnt=$((cnt + 1))
	done

	# Callback failures do not change the successful directory-change status.
	rc_emit change_dir "$old_dir" "$PWD" || :
	return 0
}

alias cd=change_dir
