#! /bin/bash

function jecho() {
    args=$*
    date=$(date +%F)
    epoch=$(date +%s)
    jDate=$(julianDate)
    prefix="| $date | $jDate | $epoch | - "
    echo -e "$prefix$args"
}

# shellcheck disable=SC2120
function julianDate() {
    d=$([[ $# -eq 0 ]] && echo $(date +%j) || echo date +%j --date=$1)
    echo "$d"
}

function readPropertyFile() {
    file=$1
    property=$2
    if [[ -f $file ]]; then 
        grep $property= $file | cut -d= -f2 | cat
    fi
}

function mkdirIfAbsent() {
    dir=$1
    if [[ ! -d $dir ]]; then
        mkdir -p $dir
    fi
}