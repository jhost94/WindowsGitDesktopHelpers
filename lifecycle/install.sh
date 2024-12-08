#! /bin/bash

### Variables
INSTALL_DIR=$HOME
PACHAGE_SCRIPT=./package.sh
BACKUP_SCRIPT=./recover_backup.sh
BACKUP_IDENTIFIER="backup$(date +%Y%m%d)"
CONFIG_FILE=$( ([[ -f "./.config.sh" ]] && echo "./.config.sh") || ([[ -f "./config.sh" ]] && echo "./config.sh") || (echo "./src/.config.sh") )

### Verify configuration
if [[ -f src/.script/lib/common.sh ]]; then
    # shellcheck disable=SC1091
    source src/.script/lib/common.sh
else
    alias jecho=echo
fi

if [[ ! -f  $CONFIG_FILE ]]; then
    jecho Config file not found
fi

# shellcheck disable=SC2086
pastasDir=$(readPropertyFile $CONFIG_FILE PASTAS_DIR)
# shellcheck disable=SC2086
userName=$(readPropertyFile $CONFIG_FILE USER_NAME)

if [[ -z $pastasDir || $userName ]]; then 
    jecho Config file not properly configured.
    exit 1
fi

### Backup current files
tempDir="/tmp/${BACKUP_IDENTIFIER}$(date +%s)"
mkdir $tempDir

cp $INSTALL_DIR/.bashrc $tempDir/
cp $INSTALL_DIR/.config.sh $tempDir/
cp -r $INSTALL_DIR/.script $tempDir/

### Zip and archive backup
mkdirIfAbsent $INSTALL_DIR/backups
if command -v zip > /dev/null 2>&1; then
    #zip $tempDir -o $INSTALL_DIR/backups/name.zip
    echo fix zip
else
    cp -r $tempDir $INSTALL_DIR/backups/
fi

### Build package
$PACHAGE_SCRIPT

### Install script files

### Run backup if necessary
$BACKUP_SCRIPT 