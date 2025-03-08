#! /usr/bin/bash

VERSION_MAP=(
    "0000001:9cd157fee455d3672ba93dea208694a9b7c0d82ee467ec3b90970905b1880a2c"
)
CONFIG_LINES=(
    "PASTAS_DIR:0"
    "USER_NAME:0"
    "PROJECTS_ROOT:0"
    "DELME_DIR:0"
    "CURRENT_HOME:0"
    "CURRENT_HOMES:1"
    "SCRIPT_DIR:0"
    "LIB_DIR:0"
    "PROGRAMFILES_DIR:0"
    "USERS_ROOT:0"
    "USER_ROOT:0"
    "USER_LOCAL_APP_DATA:0"
    "LAST_LOCATION:1"
)
USER_CONFIG="config.sh"
DEFAULT_CONFIG="src/.config/.config.sh"

configContent="#! /usr/bin/bash
"
backups=()
alreadyInstalledErrors=""
extraLinesToDelete=-1

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
    if canInstall; then
        newInstall
    else
        updateInstall
    fi
}

function updateBashRC() {
    linesToDel=$extraLinesToDelete
    bashRC=""

    if [[ -z $linesToDel ]]; then
        echo "Missing parameters:
linesToDel=$linesToDel"
        return 1
    fi

    if [[ $linesToDel != "-1" ]]; then 
        bashRC=$(sed "/:scripts_for_windows:by_jhost:on_jhub:/,+${linesToDel}d" < "$HOME/.bashrc")
    else
        bashRC=$(cat "$HOME/.bashrc")
    fi

    echo "$bashRC
$(getInstallMeta)"
}

function newInstall() {
    # no need to update and backup
    # just append:
    # ### [sha256]:scripts_for_windows:by_jhost:on_jhub:backups[...,...]
    # ### version:0000001
    # source $HOME/.scripts_for_windows
    updateBashRC=$(updateBashRC)
    echo "$updateBashRC"
}

function updateInstall() {
    updateBashRC=$(updateBashRC)
    echo "$updateBashRC"
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

    if [[ $isInstalled -eq 0 ]]; then
        echo "Is properly installed"
        echo "Installed version: "
    elif [[ $isInstalled -eq 1 ]]; then
        echo "The is something wrong with the installment:"
        readAlreadyInstalledErrors
    elif [[ $isInstalled -eq 2 ]]; then 
        echo "Not installed, can do clean install"
    else 
        echo "Unexpected exit return $isInstalled"
    fi
}

function verifyAlreadyInstalled() {
    [[ ! -f "$HOME/.bashrc" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No bashrc found at $HOME/.bashrc" && return 1

    header=$(grep ":scripts_for_windows:by_jhost:on_jhub:" $HOME/.bashrc)
    [[ -z "$header" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No header found at $HOME/.bashrc H01" && extraLinesToDelete=-1 && return 2

    header="${header#\#\#\# }"
    [[ -z "$header" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No proper header found at $HOME/.bashrc H02" && extraLinesToDelete=-1 && return 2

    version=$(grep -A1 ":scripts_for_windows:by_jhost:on_jhub:" $HOME/.bashrc)
    [[ -z "$version" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $HOME/.bashrc V01" && extraLinesToDelete=0 && return 1
    [[ $(echo "$version" | wc -l) -ne 2 ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $HOME/.bashrc V02" && extraLinesToDelete=0 && return 1
    
    version=$(echo "$version" | tail -n1)
    [[ -z "$version" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $HOME/.bashrc V03" && extraLinesToDelete=0
    
    version="${version#\#\#\# }"
    [[ -z "$version" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $HOME/.bashrc V04" && extraLinesToDelete=0
    ! echo "$version" | grep -q "version:" && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $HOME/.bashrc V05" && extraLinesToDelete=0

    version=$(echo "$version" | cut -d ":" -f2)
    [[ -z "$version" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No version found at $HOME/.bashrc V06" && extraLinesToDelete=1

    currentSHA=$(echo "$header" | cut -d ":" -f1)
    [[ -z "$currentSHA" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No sha found at $HOME/.bashrc S01" 

    name=$(echo "$header" | cut -d ":" -f2)
    [[ -z "$name" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No name found at $HOME/.bashrc N01"

    by=$(echo "$header" | cut -d ":" -f3)
    [[ -z "$by" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No by found at $HOME/.bashrc B01"

    on=$(echo "$header" | cut -d ":" -f4)
    [[ -z "$on" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No on found at $HOME/.bashrc O01"

    backupString=$(echo "$header" | cut -d ":" -f5)
    [[ -z "$backupString" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No backup found at $HOME/.bashrc B01"

    backupString="${backupString#backups}"
    if [[ -n "$backupString" ]]; then 
        backupString="${backupString%]}"
        backupString="${backupString#[}"
        parseBackups "$backupString"
    else
        alreadyInstalledErrors="${alreadyInstalledErrors}:No backup found at $HOME/.bashrc B02"
    fi

    scriptSource=$(grep -A2 ":scripts_for_windows:by_jhost:on_jhub:" $HOME/.bashrc)
    [[ $(echo "$scriptSource" | wc -l) -ne 3 ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No script found at $HOME/.bashrc S01"  && return 1
    
    scriptSource=$(echo "$scriptSource" | tail -n1)
    [[ -z "$scriptSource" ]] && alreadyInstalledErrors="${alreadyInstalledErrors}:No script found at $HOME/.bashrc S02"
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
    for lineC in "${CONFIG_LINES[@]}"; do
        line=$(echo $lineC | cut -d ':' -f1)
        skip=$(echo $lineC | cut -d ':' -f2)

        if [ "$skip" = "1" ] || verifyLine "$line"; then
            configContent="$configContent
$(getLine "$line")"
        else
            return 1
        fi
    done
    return 0
}

function verifyLine() {
    var=$1
    if [[ -z $(grep "$var=" $USER_CONFIG | cut -d'=' -f2) && -z $(grep "export $var=" $USER_CONFIG | cut -d'=' -f2) \
        && -z $(grep "$var=" $DEFAULT_CONFIG | cut -d'=' -f2) && -z $(grep "export $var=" $DEFAULT_CONFIG | cut -d'=' -f2) ]]; then
        echo "Var: $USER_CONFIG $(grep "$var=" $USER_CONFIG | cut -d'=' -f2)"
        echo "export Var: $USER_CONFIG $(grep "export $var=" $USER_CONFIG | cut -d'=' -f2)"
        echo "Var: $DEFAULT_CONFIG $(grep "$var=" $DEFAULT_CONFIG | cut -d'=' -f2)"
        echo "export Var: $DEFAULT_CONFIG $(grep "export $var=" $DEFAULT_CONFIG | cut -d'=' -f2)"
        return 1
    else
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