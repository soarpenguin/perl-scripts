#!/bin/env bash

INTERVAL=5m;
THRESHOLD=70;
IDLE=`expr 100 - $THRESHOLD`;
EMAIL="zhuyefeng@baidu.com";
HOSTNAME=`hostname`;

function watch_cpu
{
    local idle=`mpstat | grep 'all' | awk '{print $11}'`;
    idle=${idle%%.*};

    return $idle;
}

function send_mail
{
    echo "$1 error: The CPU load is outride $2." | \
        mail -s  "$1 cpu overload." "$3";
}

while getopts "t:i:m:" opt; do
    case $opt in
        t)
            let THRESHOLD=$OPTARG;
            IDLE=`expr 100 - $THRESHOLD`;
            # echo "The threshold is: $THRESHOLD";
            ;;
        i)
            INTERVAL="${OPTARG}m";
            # echo "The interval is:$INTERVAL";
            ;;
        m)
            EMAIL="${OPTARG}";
            ;;
        *)
            ;;
    esac
    
done

watch_cpu;

if [ $? -lt $IDLE ]; then
    # echo "$HOSTNAME mail errors.";
    send_mail $HOSTNAME $THRESHOLD $EMAIL;
fi

