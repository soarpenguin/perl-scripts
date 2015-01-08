#!/usr/bin/env bash

conf_max_currency=10;
max=50;
conf_sem_file=/tmp/tmp.fifo.$$
user=`whoami`;

function remote_cp
{
    #`scp $1 $2`;
    echo "$i: scp $conffile => $targetfile";
}

#init
mkfifo ${conf_sem_file};
exec 4<>${conf_sem_file}
rm -f ${conf_sem_file}

conf_max_currency=$1;
max=$2;
service=$3;
conffile=$4;
oldconffile=$5;

prefix=${service%%.*};
suffix=${service##*.};

for ((i=0; i<${conf_max_currency}; i++))
do
    echo >&4
done

for ((i=0; i<$max; ++i))
do
    read <&4
    {
        #do your job here
        targetfile="$user@${prefix}${i}.${suffix}:$oldconffile";
        #echo "$i: scp $conffile => $targetfile";
        remote_cp $conffile $targetfile;
        #sleep 1s;
        echo >&4; #write to fifo means free sem
    }&
done
