#!/bin/bash

###########################################################################
# TEMPLY - a simple template engine written in bash
# Author: Leonard Marschke <github@marschke.me>
# License: MIT
###########################################################################

# main function you will call with your bash script
function temply {
	# replace tags which includes files ({include=FILENAME})
	function replaceFiles {
		echo "Replacing $1" >&2
		# get our base template which we want to replace in
		local template=`cat $1`
		# get the directory of the path in order to include all other files relativly
		local includePath=`dirname $1`
		# build our regex to match the include tags
		local re='(.*)\{include=([[:alnum:]_-.]+)\}(.*)'
		# do for all include tags
		while [[ $template =~ $re ]]; do
			# replace files recursivly
			local rep=$(replaceFiles ${includePath}/${BASH_REMATCH[2]})
			# replace tag with real file
			local template="${BASH_REMATCH[1]}${rep}${BASH_REMATCH[3]}"
		done

		# return our replaced template
		echo "$template"
	}

	# replace variables we find in template
	function replaceVars {
		local template="$1"
		# build our regex to match variable tags
		local re='(.*)\{\$([[:alnum:]_-.]+)\}(.*)'
		# do for all variable tags
		while [[ $template =~ $re ]]; do
			local key="${BASH_REMATCH[2]}"
			# check if the key exists in the variable array
			if [ ${vars[$key]+yes} ]; then
				# it exists: replace the variable
				local rep="${vars[$key]}"
			else
				# it does not exist: throw a warning and drop the tag
				echo "WARNING: $key is not in your vars array!" >&2
				local rep=""
			fi
			local template="${BASH_REMATCH[1]}${rep}${BASH_REMATCH[3]}"
		done

		# and finally return the processed template
		echo "$template"
	}

	local result=$(replaceFiles $1)

	# do we got a variable array?
	if [ "$2" != "" ]; then
		# link the global var we got to our vars array
		declare -n vars=$2
	else
		# throw a warning because we don't got any variables array
		echo "WARNING: No variables array passed!" >&2

		# declare an empty array for variables (so the function will not fail)
		declare -A vars
	fi

	# call the variable substitution function
	result=$(replaceVars "${result}")

	# return our final result
	echo "$result"
}
