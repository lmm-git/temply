#!/bin/bash

function parseTemplate {
	function replaceFiles {
		echo "Replacing $1" >&2
		local template=`cat $1`
		local includePath=`dirname $1`
		local re='(.*)\{include=([[:alnum:]_-.]+)\}(.*)'
		while [[ $template =~ $re ]]; do
			echo "${BASH_REMATCH[2]}" >&2
			echo "REMATCHEND" >&2
			local rep=$(replaceFiles ${includePath}/${BASH_REMATCH[2]})
			local template="${BASH_REMATCH[1]}${rep}${BASH_REMATCH[3]}"
		done
		echo "$template"
	}

	function replaceVars {
		local template="$1"
		local re='(.*)\{\$([[:alnum:]_-.]+)\}(.*)'
		while [[ $template =~ $re ]]; do
			local key="${BASH_REMATCH[2]}"
			if [ ${vars[$key]+yes} ]; then
				local rep="${vars[$key]}"
			else
				echo "WARNING: $key is not in your vars array!" >&2
				local rep=""
			fi
			local template="${BASH_REMATCH[1]}${rep}${BASH_REMATCH[3]}"
		done
		echo "$template"
	}

	local result=$(replaceFiles $1)

	# do we got a variable array?
	if [ "$2" != "" ]; then
		declare -n vars=$2
	else
		echo "WARNING: No variables array passed!" >&2
		declare -A vars
	fi
	result=$(replaceVars "${result}")

	echo "$result"
}
