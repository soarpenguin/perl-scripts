#!/bin/bash

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

trap "rm -f ${tmp_file}; exit" INT TERM EXIT  

for ((i=0;i<${g_THREAD_NUM};i++))
do
    echo >&9
done

unset HOST
for HOST in `cat ${g_HOST_LIST}`
do
    echo "start  ${HOST} ......"
    read <&9

    (${SSH} ${HOST} "ls "  &>  log/${HOST}; echo >&9) &

done
rm -f ${tmp_file}
exec 9<&-
