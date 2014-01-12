#!/bin/bash

MYNAME="${0##*/}"
report_err() { echo "${MYNAME}: Error: $*" >&2 ; }

if [ -t 1 ]
then
    RED="$( echo -e "\e[31m" )"
    HL_RED="$( echo -e "\e[31;1m" )"
    HL_BLUE="$( echo -e "\e[34;1m" )"

    NORMAL="$( echo -e "\e[0m" )"
fi

_hl_red()    { echo "$HL_RED""$@""$NORMAL";}
_hl_blue()   { echo "$HL_BLUE""$@""$NORMAL";}

_trace() {
    echo $(_hl_blue '  ->') "$@" >&2
}

_print_fatal() {
    echo $(_hl_red '==>') "$@" >&2
}

usage() { _print_fatal "Usage: bash ${MYNAME} hostlist."; }
if [ $# -lt 1 ] || [ ! -e "$1" ]; then
	usage
	exit 1
fi

g_HOST_LIST=$1
g_THREAD_NUM=300
tmp_file="pipe.$$"
SSH="ssh -n -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=5 "
SCP='scp -q -r -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=5 '

if [ -d log ]; then
    rm -rf log
fi

mkdir -p log

mkfifo ${tmp_file}
exec 9<>${tmp_file}

#trap "rm -f ${tmp_file}; exit" INT TERM EXIT  
cleanup() { rm -f "${tmp_file}" ; }
trap cleanup EXIT TERM EXIT;

#trap 'rm -f "${tmp_file}"; exit $?' INT TERM EXIT

for ((i=0;i<${g_THREAD_NUM};i++))
do
    echo >&9
done

unset HOST
for HOST in `cat ${g_HOST_LIST}`
do
    _trace "start  ${HOST} ......"
    read <&9

    (${SSH} ${HOST} "ls "  &>  log/${HOST}; echo >&9) &

done
rm -f ${tmp_file}
#trap - INT TERM EXIT
exec 9<&-
