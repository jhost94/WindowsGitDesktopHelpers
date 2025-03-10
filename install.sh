#! /usr/bin/bash

function getDateForFolder() {
    date=$1
    if [[ -z $date ]]; then
        date +%Y/%m/%d
    else
        date +%Y/%m/%d -d "$date"
    fi
}


VERSION_MAP=(
    "0000001:9cd157fee455d3672ba93dea208694a9b7c0d82ee467ec3b90970905b1880a2c"
)
CONFIG_LINES=(
    "PASTAS_DIR:Missing configuration"
    "USER_NAME:Missing configuration"
)
USER_CONFIG="config.sh"
DEFAULT_CONFIG="src/.config/.config.sh"
BASH_RC="$HOME/.bashrc"
SCRIPT_DIR="$HOME/.scripts_for_windows"
# shellcheck disable=SC2119
BACKUP_DIR="$SCRIPT_DIR/backup/$(getDateForFolder)"

backups=()
alreadyInstalledErrors=""
extraLinesToDelete=-1
configLineValues=()

### IFNOT: create new reference on .bashrc
### ### [sha256]:scripts_for_windows:by_jhost:on_jhub:backups[...,...]
### ### version:0000001
### source $HOME/.scripts_for_windows.sh
### install .script folder
### do a health-check, if failed give eror
### done
### IFYES: check version, already installed? if yes stop and give warning
### verify config
### ifno: delete id, version and source lines, save backups in order
### add new ones
### backup current install, and add to backups as FILO (Fist In Last Out)
### do the install
### do a health-check, restore backup if failed and give error
### done

function install() {
    canInstall
    installStatus=$?

    if [[ $installStatus == 0 ]]; then
        newInstall
    elif [[ $installStatus == 1 ]]; then
        echo "Error in install. Aborting."
        return 1
    elif [[ $installStatus == 2 ]]; then
        updateInstall
    elif [[ $installStatus == 3 ]]; then
        updateInstall
    else
        echo "Error, unexpected install verification status. Aborting."
        return 1
    fi
}

function updateBashRC() {
    linesToDel=$extraLinesToDelete
    bashRC=""

    if [[ $linesToDel != "-1" ]]; then 
        bashRC=$(sed "/:scripts_for_windows:by_jhost:on_jhub:/,+${linesToDel}d" < "$BASH_RC")
    else
        bashRC=$(cat "$BASH_RC")
    fi

    echo "$bashRC
$(getInstallMeta)"
}

function newInstall() {
    prepareInstall
    updateBashRC=$(updateBashRC)
    config=$(generateConfig)
    echo "New install of Scripts For Windows"
    echo "Version: $(getVersion)"

    echo "Installing scripts"
    current=$(pwd)
    cp -r "$current/src" "$SCRIPT_DIR/"
    cp "$current/src/.scripts_for_windows.sh" "$HOME/"

    echo "Updating config"
    echo "$config" > "$SCRIPT_DIR/.config/.config.sh"

    echo "Updating .bashrc"
    echo "$updateBashRC" > "$BASH_RC"

    echo "Rebooting .bashrc"
    # shellcheck disable=SC1090
    source "$BASH_RC"

    echo "Done!"
}

function updateInstall() {
    prepareInstall 1
    updateBashRC=$(updateBashRC)
    config=$(generateConfig)
    echo "Updating Scripts For Windows"
    echo "Version: $(getVersion)"

    echo "Installing scripts"
    current=$(pwd)
    cp -r "$current/src" "$SCRIPT_DIR/"
    cp "$current/src/.scripts_for_windows.sh" "$HOME/"

    #save config?
    echo "Updating config"
    echo "$config" > "$SCRIPT_DIR/.config/.config.sh"
    
    echo "Updating .bashrc"
    echo "$updateBashRC" > "$BASH_RC"

    echo "Rebooting .bashrc"
    # shellcheck disable=SC1090
    source "$BASH_RC"

    echo "Done!"
}

function prepareInstall() {
    isUpdate=$1
    # backup .bashrc
    mkdir -p "$SCRIPT_DIR/.config"
    mkdir -p "$SCRIPT_DIR/.script"
    mkdir -p "$BACKUP_DIR/.config"
    mkdir -p "$BACKUP_DIR/.script"
    cp "$BASH_RC" "$BACKUP_DIR/"

    if [[ $isUpdate == "1" ]]; then
        rm -r "${BACKUP_DIR:?}/"
        cp -r "$SCRIPT_DIR/.config" "$BACKUP_DIR/"
        cp -r "$SCRIPT_DIR/.script" "$BACKUP_DIR/"
        # add it to the $backups
        # backup schema
        # [version]:[sha256]:[location]
        backups+=("$(getVersion):$(getSha):${BACKUP_DIR}")
    else
        echo "no update"
    fi
}

function postInstallFail() {
    isUpdate=$1
    cp "$BACKUP_DIR/.bashrc" "$BASH_RC"
    
    if [[ $isUpdate == "1" ]]; then
        cp -r "$BACKUP_DIR/.config" "$SCRIPT_DIR/.config/"
        cp -r "$BACKUP_DIR/.script" "$SCRIPT_DIR/.script/"
        # remove it from the $backups
    else
        echo "no update"
    fi
}

function generateConfig() {
    content=""

    while read -r line; do
    if lineIsToBeChanged "$line"; then
        content="$content
$(getConfigLineValue "$line")"
    else
        content="$content
$line"
    fi
    done < $DEFAULT_CONFIG

    echo "$content" | sed '1d'
}

function getConfigLineValue() {
    line=$1

    for lineC in "${configLineValues[@]}"; do
        key=$(echo "$lineC" | cut -d ':' -f1)
        val=$(echo "$lineC" | cut -d ':' -f2)
        
        if echo "$line" | grep "$key" -q; then
            echo "$val"
            return 0
        fi
    done
}

function lineIsToBeChanged() {
    line=$1
     
    for lineC in "${CONFIG_LINES[@]}"; do
        key=$(echo "$line" | cut -d '=' -f1)
        if echo "$key" | grep "$lineC" -q; then
            return 0
        fi
    done
    return 1
}

function getInstallMeta() {
    backupString=$(stringifyBackups)
    sha=$(getSha)
    version=$(getVersion)
    echo "
### $sha:scripts_for_windows:by_jhost:on_jhub:backups[$backupString]
### version:$version
source $HOME/.scripts_for_windows.sh"
}

function getSha() {
    echo "9cd157fee455d3672ba93dea208694a9b7c0d82ee467ec3b90970905b1880a2c"
}

function getVersion() {
    echo "0000001"
}

function canInstall() {
    verifyAlreadyInstalled
    isInstalled=$?
    returnValue=0

    if ! verifyConfig; then
        echo "Error in config"
        return 1
    fi

    if [[ $isInstalled -eq 0 ]]; then
        echo "Is properly installed"
        echo "Installed version: "
        returnValue=2
    elif [[ $isInstalled -eq 1 ]]; then
        echo "The is something wrong with the installment:"
        readAlreadyInstalledErrors
        returnValue=3
    elif [[ $isInstalled -eq 2 ]]; then 
        echo "Not installed, can do clean install"
        returnValue=0
    else 
        echo "Unexpected exit return $isInstalled"
        returnValue=4
    fi

    return $returnValue
}

function verifyAlreadyInstalled() {
    [[ ! -f "$BASH_RC" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No bashrc found at $BASH_RC" && return 1

    header=$(grep ":scripts_for_windows:by_jhost:on_jhub:" "$BASH_RC")
    [[ -z "$header" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No header found at $BASH_RC H01" && extraLinesToDelete=-1 && return 2

    header="${header#\#\#\# }"
    [[ -z "$header" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No proper header found at $BASH_RC H02" && extraLinesToDelete=-1 && return 2

    version=$(grep -A1 ":scripts_for_windows:by_jhost:on_jhub:" "$BASH_RC")
    [[ -z "$version" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $BASH_RC V01" && extraLinesToDelete=0 && return 1
    [[ $(echo "$version" | wc -l) -ne 2 ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $BASH_RC V02" && extraLinesToDelete=0 && return 1
    
    version=$(echo "$version" | tail -n1)
    [[ -z "$version" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $BASH_RC V03" && extraLinesToDelete=0
    
    version="${version#\#\#\# }"
    [[ -z "$version" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $BASH_RC V04" && extraLinesToDelete=0
    ! echo "$version" | grep -q "version:" && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $BASH_RC V05" && extraLinesToDelete=0

    version=$(echo "$version" | cut -d ":" -f2)
    [[ -z "$version" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $BASH_RC V06" && extraLinesToDelete=1

    currentSHA=$(echo "$header" | cut -d ":" -f1)
    [[ -z "$currentSHA" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No sha found at $BASH_RC S01" 

    name=$(echo "$header" | cut -d ":" -f2)
    [[ -z "$name" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No name found at $BASH_RC N01"

    by=$(echo "$header" | cut -d ":" -f3)
    [[ -z "$by" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No by found at $BASH_RC B01"

    on=$(echo "$header" | cut -d ":" -f4)
    [[ -z "$on" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No on found at $BASH_RC O01"

    backupString=$(echo "$header" | cut -d ":" -f5)
    [[ -z "$backupString" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No backup found at $BASH_RC B01"

    backupString="${backupString#backups}"
    if [[ -n "$backupString" ]]; then 
        backupString="${backupString%]}"
        backupString="${backupString#[}"
        parseBackups "$backupString"
    else
        alreadyInstalledErrors="${alreadyInstalledErrors}:No backup found at $BASH_RC B02"
    fi

    scriptSource=$(grep -A2 ":scripts_for_windows:by_jhost:on_jhub:" "$BASH_RC")
    [[ $(echo "$scriptSource" | wc -l) -ne 3 ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No script found at $BASH_RC S01"  && return 1
    
    scriptSource=$(echo "$scriptSource" | tail -n1)
    [[ -z "$scriptSource" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No script found at $BASH_RC S02"
    extraLinesToDelete=2

    [[ -z $alreadyInstalledErrors ]] && return 0 || return 1
}

function readAlreadyInstalledErrors() {
    msg=$(echo "$alreadyInstalledErrors" | tr ':' '\n')
    for error in "${msg[@]}"; do
        echo "$error"
    done
}

function parseBackups() {
    string=$1
    string=$(echo "$string" | tr ',' ' ')
    # shellcheck disable=SC2206
    backups+=($string)
}

function stringifyBackups() {
    string=""
    for e in "${backups[@]}"; do
        string="${string},$e"
    done
    echo "${string#,}"
}

function verifyConfig() {
    for line in "${CONFIG_LINES[@]}"; do
        key=$(echo "$line" | cut -d ':' -f1)
        errorMessage=$(echo "$line" | cut -d ':' -f2)

        if ! verifyLine "$key"; then
            echo "Config line error in:"
            echo "$key"
            echo "Error:"
            echo "$errorMessage"
            return 1
        fi
    done
    return 0
}

function verifyLine() {
    var=$1
    if [[ -z $(grep "$var=" $USER_CONFIG | cut -d'=' -f2) && -z $(grep "export $var=" $USER_CONFIG | cut -d'=' -f2) \
        && -z $(grep "$var=" $DEFAULT_CONFIG | cut -d'=' -f2) && -z $(grep "export $var=" $DEFAULT_CONFIG | cut -d'=' -f2) ]]; then
        return 1
    else
        configLineValues+=("${var}:$(getLine "$var")")
        return 0
    fi
}

function getLine() {
    var=$1
    if [[ -n $(grep "$var=" $USER_CONFIG | cut -d'=' -f2) ]]; then
        grep "$var=" $USER_CONFIG
    elif [[ -n $(grep "export $var=" $USER_CONFIG | cut -d'=' -f2) ]]; then
        grep "export $var=" $USER_CONFIG
    elif [[ -n $(grep "$var=" $DEFAULT_CONFIG | cut -d'=' -f2) ]]; then
        grep "$var=" $DEFAULT_CONFIG
    elif [[ -n $(grep "export $var=" $DEFAULT_CONFIG | cut -d'=' -f2) ]]; then
        grep "export $var=" $DEFAULT_CONFIG
    else
        echo ""
    fi
}

install