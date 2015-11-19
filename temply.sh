#!/bin/bash

function parseTemplate {
	function existsKey {
		if [ "$2" != in ]; then
			echo "Incorrect usage."
			echo "Correct usage: existsKey {key} in {array}"
			return
		fi
		eval '[ ${'$3'[$1]} ]'
	}

	function replaceFiles {
		echo "Replacing $1" >&2
		local template=`cat $1`
		local includePath=`dirname $1`
		local re='(.*)!FILE<(.*)>(.*)'
		while [[ $template =~ $re ]]; do
			local rep=$(replaceFiles ${includePath}/${BASH_REMATCH[2]})
			template="${BASH_REMATCH[1]}${rep}${BASH_REMATCH[3]}"
		done
		echo "$template"
	}

	function replaceVars {
		local template="$1"
		local params="$2"
		local re='(.*)!VAR<(.*)>(.*)'
		while [[ $template =~ $re ]]; do
			local key="${BASH_REMATCH[2]}"
			if existsKey $key in $params; then
				local rep="${params[$key]}"
			else
				echo "WARNING: $key is not in your params array!" >&2
				local rep=""
			fi
			template="${BASH_REMATCH[1]}${rep}${BASH_REMATCH[3]}"
		done
		echo "$template"
	}

	local result=$(replaceFiles $1)

	# do we got a variable array?
	params="$2"
	if [[ "$(declare -p params)" =~ "declare -A" ]]; then
		replaceVars "${result//'/\'}" params
	fi

	echo "$result"
}
