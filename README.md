# temply
An easy template engine to build config files written in bash for bash

## Usage

### Include the engine
You have to source the ```temply.sh``` file once. After sourcing it you can call the template engine like


### Our first call
```bash
# declare some params we can use as vars in our template files and if statements
# the first declare will declare a array which contains our variables
declare -A params
params[awesomevar1]="TEMPLY"
params[be_cool]="I am cool!"
params[myVar]="${myVar}"
params[myInt]="20"
...........

# and call the temply engine
temply myTemplate params > myOutputFile
#      ^^^^^^^^^^
#      This is your template name. You can specify any file relativly to your current working directory
```

By calling this command you will get status messages at standard output 2 and receive the processed template by standard output 1. In this case you will write the processed template into the file myOutputFile in your current working directory.

### Creating the templates
And for myTemplate you can create a file like
```
# This is my test configuration file

# Replace a variable
{$awesomevar}

# Do an if
{if $awesomevar == "TEMPLY"}
	Do this only if my awesomevar is equal to TEMPLY
{/if}

# Do another if
{if $awesomevar != "TEMPLY"}
	Do this only if my awesomevar is NOT equal to TEMPLY
{/if}

# Include another file
{include=subdir/another_file}
```

### Use of include

Possible content of subdir/another_file
```
{include=myInclude}
```

This will include the file subdir/myInclude into the file subdir/another_file and then into myTemplate.

Please note: All includes are relative to the place of the file which includes the include.

### Possible if statements
```
{if $awesomevar != "TEMPLY"}
	Do this only if my awesomevar is NOT equal to TEMPLY
{/if}

{if $myInt -le "10"}
	Do this only if my awesomevar is lower or equal than 10
{/if}

{if $myInt -lt "10"}
	Do this only if my awesomevar is lower than 10
{/if}

{if $myInt -ge "10"}
	Do this only if my awesomevar is greater or equal than 10
{/if}

{if $myInt -gt "10"}
	Do this only if my awesomevar is greater than 10
{/if}
```

## Contribute
You are welcome to contribute to this project. Simply open a pull request and do your code changes!
