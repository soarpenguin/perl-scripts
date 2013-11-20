#!/bin/env bash

if [ $# ne 2 ]; then
    echo "$0 delfile sourcefile"
    exit 1
fi

file=$1
all_line_sed=$2

for line in `cat ${file}`
do
    fgrep "${line}" ${all_line_sed} &>/dev/null
    if [ $? -ne 0 ];then
        continue
    fi

    sed -e "/${line}/d" ${all_line_sed} >${all_line_sed}.tmp
    mv ${all_line_sed}.tmp ${all_line_sed}
done
