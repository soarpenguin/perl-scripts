#!/usr/bin/env bash

CONFFILE="update.conf";
OLDCONFFILE="oldupdate.conf";
max_currency=10;
total=50;
declare -a SERVICES;
declare -a CONFFILES;
INDEX=0;

if [ $# -gt 0 ]; then
    CONFFILE=$1;
    shift;
fi

if [[ ! -e $CONFFILE ]]; then
    echo "The configure file is not existed!";
    exit 2;
fi

while read LINE
do
    SERVICES[$INDEX]=`echo $LINE | cut -d ' ' -f 1`;
    CONFFILES[$INDEX]=`echo $LINE | cut -d ' ' -f 2`;
    let "INDEX+=1"; 
done < "$CONFFILE"

echo "----------------------------";
echo ${SERVICES[@]};
echo ${CONFFILES[@]};

COUNT=$(($INDEX-1));
echo $COUNT;

for i in `seq 0 $COUNT`; do
    {
        # update 10 50 ${SERVICES[$i]} ${CONFFILES[$i]} $OLDCONFFILE;
        echo ${SERVICES[$i]};
        echo ${CONFFILES[$i]};
        ~/scripts/test02/parallel.sh $max_currency $total ${SERVICES[$i]} ${CONFFILES[$i]} $OLDCONFFILE;
        # echo "done.";
    }&
done

wait;
echo "done.";
