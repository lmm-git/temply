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

	function handleIf {
		echo "Processing if statements... This might take a while" >&2
		local template="$1"
		# build our regex to match variable tags
		local startRe='(.*)\{if (((\$)?[[:alnum:]_.{}"]+) (==|!=|-gt|-lt|-le|-ge) ((\$)?[[:alnum:]_.{}"]+))\}(.*)'
		# local endRe='(.*)\{\/if\}(.*)' <-- currently not needed

		# do for all variable tags
		while [[ $template =~ $startRe ]]; do
			# store BASH_REMATCH vars in local variables because we will override BASH_REMATCH before we need theese vars
			local beforeRegex="${BASH_REMATCH[1]}"
			local afterRegex="${BASH_REMATCH[8]}"
			local op1="${BASH_REMATCH[3]}"
			local op2="${BASH_REMATCH[6]}"
			local comp="${BASH_REMATCH[5]}"
			local restStr="${BASH_REMATCH[8]}"

			# initialise some variable for the for loop
			local openIf=1
			local innerIf=''
			local checkStr=''
			# loop through each char in rest string
			for (( i=0; i<${#restStr}; i++ )); do
				local checkStr="${checkStr}${restStr:$i:1}"
				local innerIf="${innerIf}${restStr:$i:1}"

				# empty the checkstring on newlines because we cannot have tags over multiple lines
				if [ "${restStr:$i:1}" == $'\n' ]; then
					local checkStr=''
					continue
				fi

				# if we do not have a } at the enf of our checkstr our regexes cannot match (performance improvement)
				if [ "${restStr:$i:1}" != '}' ]; then
					continue
				fi

				if [ "${checkStr:(-5)}" == '{/if}' ]; then
					# we found a closing tag, so decrease our open ifs
					checkStr=''
					let "openIf -= 1"
					# check if we have no open ifs left (we found the closing tag for our if)
					if [ "$openIf" -le 0 ]; then
						break;
					fi
				elif [[ "$checkStr" =~ $startRe ]]; then
					# we found another if, so increase our open ifs
					checkStr=''
					let "openIf += 1"
				fi
			done
			# hmm if we get here the template is invalid
			if [ "$openIf" -gt 0 ]; then
				echo "Invalid template syntax! Check if you are closing all your if statements!" >&2
				return
			fi

			# define the regex to match variables
			local varRegex='\$([[:alnum:]_]+)'

			# replace variables with them we got as argument
			if [[ "$op1" =~ $varRegex ]]; then
				op1="\"${vars[${BASH_REMATCH[1]}]}\""
			fi
			if [[ "$op2" =~ $varRegex ]]; then
				op2="\"${vars[${BASH_REMATCH[1]}]}\""
			fi

			# do the comparsion of our if statement
			if [ $op1 $comp $op2 ]; then
				# add the text which stands before the regex,
				# our text inside the if (minus 5 chars for our closing tag at the end) and
				# all the text coming after the closing if tag
				template="${beforeRegex}${innerIf::-5}${afterRegex:${#innerIf}}"
			else
				# add the text which stands before the regex,
				# all the text coming after the closing if tag
				template="${beforeRegex}${afterRegex:${#innerIf}}"
			fi
		done

		# return our processed template
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

	# process if statements
	result=$(handleIf "${result}")

	# return our final result
	echo "$result"
}
