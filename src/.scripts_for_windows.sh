#! /usr/bin/bash

### Common variables
CONFIG_FILE=$HOME/.scripts_for_windows/.config/.config.sh

### git fixes
# shellcheck disable=SC2121
set GIT_TRACE_PACKET=1
# shellcheck disable=SC2121
set GIT_TRACE=1
# shellcheck disable=SC2121
set GIT_CURL_VERBOSE=1

### Import config ###
# shellcheck disable=SC1090
source "$CONFIG_FILE"

### ALIASES ###
# shellcheck disable=SC1112
alias screensave='powershell.exe -command "& (Get-ItemProperty ‘HKCU:Control Panel\Desktop’).{SCRNSAVE.EXE}"'
alias cdhome='cd $CURRENT_HOME'
alias vibash='vim $HOME/.bashrc'
alias inibash='source $HOME/.bashrc'
alias vibash_profile='vim $HOME/.bash_profile'
alias inibash_profile='source $HOME/.bash_profile'
alias savedir='LAST_LOCATION=$(pwd)'
alias cdback='cd $LAST_LOCATION'
alias chrome='"$PROGRAMFILES_DIR/Google/Chrome/Application/chrome.exe"'
alias code='"$USER_LOCAL_APP_DATA/Programs/Microsoft VS Code/Code.exe"'

### SCRIPTS ###
alias viscript='. $SCRIPT_DIR/viscript.sh'
alias getpw='bash $SCRIPT_DIR/getpw.sh'

alias sudo=run_as_admin "$@"
alias checknetwork='bash $SCRIPTS_ROOT/check_network.sh'

# Functions
run_as_admin() {
	# NEED WORK, A LOT OF WORK
	ARGUMENTS=$@
	args=""

	if [ ${#ARGUMENTS[0]} -eq 0 ]; then
		return
	fi

	for a in $ARGUMENTS; do
		args+="${a} "
	done
	
	length=$((${#args} - 1))
	
	args="${args:0:$length}"

	runas /user:"$USER_NAME" "$args"
}