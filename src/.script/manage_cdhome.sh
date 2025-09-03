#! /usr/bin/bash

### sethome
function set_home() {
    if [[ -d "$1" ]]; then
        dir=$(realpath "$1")
        export CURRENT_HOME="$dir"
    else
        echo "Error, cannot find directory $1"
    fi
}

### checkhome
function check_home() {
    echo "$CURRENT_HOME"
}

### sethome n
function set_home_n() {
    homeN=$1
    dir=$2
    HOMES_FILE="$HOME/.scripts_for_windows/.config/homes"
    homeN_re=$(printf '%s' "$homeN" | sed 's/[][(){}.^$*+?\\|]/\\&/g')
    dir_esc=${dir//\\/\\\\}   # escape backslashes
    dir_esc=${dir_esc//&/\\&} # escape &

    # shellcheck disable=SC2046
    if [ $(home_n_exists "$homeN_re") == "true" ]; then
        echo ""
        export CURRENT_HOMES=$(echo "$CURRENT_HOMES" | sed -E "s@(^|:)(${homeN_re})=[^:]*@\1\2=${dir_esc}@")
        if [[ -f "$HOMES_FILE" ]]; then
            echo "$CURRENT_HOMES" > "$HOMES_FILE"
        fi
    else
        export CURRENT_HOMES="$CURRENT_HOMES:$homeN_re=$dir_esc"
        if [[ -f "$HOMES_FILE" ]]; then
            echo "$CURRENT_HOMES" > "$HOMES_FILE"
        fi
    fi
}

### check n
function check_home_n() {
    homeN=$1
    # shellcheck disable=SC2046
    if [ $(home_n_exists "$homeN") == "true" ]; then
        value=$(echo "$CURRENT_HOMES" | grep -oE "$homeN=[^:]+" | sed "s/$homeN=//")
        echo "$value"
    else
        echo "No home found for $homeN"
    fi
}
### checkhomes
function check_homes() {
    list=$(echo "$CURRENT_HOMES" | tr ':' '\n')
    echo "$list"
}

### cdhome n
function cdhome_n() {
    homeN=$1
    # shellcheck disable=SC2046
    if [ $(home_n_exists "$homeN") == "true" ]; then
        value=$(echo "$CURRENT_HOMES" | grep -oE "$homeN=[^:]+" | sed "s/$homeN=//")
        cd "$value" || echo "Error: cd $value: $!"
    else
        echo "No home found for $homeN"
    fi
}

function home_n_exists() {
    homeN=$1
    if echo "$CURRENT_HOMES" | grep -q "$homeN"; then
        echo "true"
    else
        echo "false"
    fi
}

is_number() {
  [[ "$1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]
}