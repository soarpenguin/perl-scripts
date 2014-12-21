#!/usr/bin/env bash

if [ $# -ne 2 ]; then
    echo "$0 delfile sourcefile"
    exit 1
fi

file=$1
sourcefile=$2

die()
{
	result=$1
	shift
	printf "%s\n" "$*" >&2
	exit $result
}

checkfile()
{
	[ -n $1 ] || die 1 "file name is null."
	[ -f $1 ] || die 1 "check existence of file: $1."
}

checkfile $file
checkfile $sourcefile

for line in `cat ${file}`
do
    fgrep "${line}" ${sourcefile} &>/dev/null
    if [ $? -ne 0 ];then
        continue
    fi

    sed -e "/\<${line}\>/d" ${sourcefile} >${sourcefile}.tmp
    mv ${sourcefile}.tmp ${sourcefile}
done


