#!/usr/bin/env bash

host=$1;

if [ ! -e $host ]; then
    echo "Please check the file of $host.";
    usage;
fi

for i in `cat $host`
do
    #echo $i;
    #host $i;
    ip=$(host $i | grep -oP "(\d+\.){3}\d+");
    echo $ip;
done

function usage {
    echo "bash $0 hostlist";
    exit 1;
}
