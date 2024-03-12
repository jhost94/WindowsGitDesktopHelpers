#! bin/bash

### git fixes
set GIT_TRACE_PACKET=1
set GIT_TRACE=1
set GIT_CURL_VERBOSE=1

### Import config ###
source $HOME/.config.sh

### ALIASES ###
alias screensave='powershell.exe -command "& (Get-ItemProperty ‘HKCU:Control Panel\Desktop’).{SCRNSAVE.EXE}"'
alias cdhome='cd $CURRENT_HOME'
alias vibash='vim $HOME/.bashrc'
alias inibash='source $HOME/.bashrc'

### SCRIPTS ###
alias viscript='. $SCRIPT_DIR/viscript.sh'
alias getpw='bash $SCRIPT_DIR/getpw.sh'