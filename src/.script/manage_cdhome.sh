#! bin/bash

### sethome
function set_home() {
    if [[ -d "$1" ]]; then
        dir=$(realpath $1)
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
    if [ $(home_n_exists $homeN) ]; then
        export CURRENT_HOMES=$(echo "$CURRENT_HOMES" | sed -E "s/($homeN)=([^:]*)/\1=$dir/")
    else
        export CURRENT_HOMES=":$homeN=$dir"
    fi
}

### cdhome n
function check_home_n() {
    homeN=$1
    if [ $(home_n_exists $homeN) ]; then
        value=$(echo "$CURRENT_HOMES" | grep -oE "$homeN=[^:]+" | sed "s/$homeN=//")
        echo "$value"
    else
        echo "No home found for $homeN"
    fi
}
### checkhomes
function check_homes() {
    list=$(echo $CURRENT_HOMES | tr ':' '\n')
    echo "$list"
}

### cdhome n
function cdhome_n() {
    homeN=$1
    if [ $(home_n_exists $homeN) ]; then
        value=$(echo "$CURRENT_HOMES" | grep -oE "$homeN=[^:]+" | sed "s/$homeN=//")
        cd "$value"
    else
        echo "No home found for $homeN"
    fi
}

function home_n_exists() {
    homeN=$1
    if [ echo "$CURRENT_HOMES" | grep -q "$homeN" ]; then
        return 0
    else
        return 1
    fi
}

is_number() {
  [[ "$1" =~ ^-?[0-9]+(\.[0-9]+)?$ ]]
}