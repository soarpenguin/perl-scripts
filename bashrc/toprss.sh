#!/usr/bin/env bash

for pid in `ls /proc/ | grep "^[0-9]"`
do
    if [ -f /proc/$pid/statm ]; then
        tep=`cat /proc/$pid/statm | awk '{print ($2)}'`
        rss=`expr $rss + $tep`
    fi
done

rss=`expr $rss \* 4`
echo $rss "kb"
