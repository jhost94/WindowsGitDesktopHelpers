#! bin/bash

###########################################################
### Edits a script in the scrip folder or creates a new ###
### one with the #! bin/bash already on the file.       ###
### This script is to edit/create using vim             ###
###########################################################

FILE_NAME="$1.sh"
W_DIR=$SCRIPT_DIR
FILE_PATH="$W_DIR/$FILE_NAME"

if [[ -f "$FILE_PATH" ]]; then
    vim "$FILE_PATH"
else
        echo "#! bin/bash
" >> "$FILE_PATH"
        vim "$FILE_PATH"
fi
