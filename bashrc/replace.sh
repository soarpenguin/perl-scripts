#!/bin/sh

#Example Usage: ./replace.sh *.txt aaaa bbbb"
usage()
{
        echo "./replace.sh \"file_type\" src_string dst_string"
        echo "Exapmle: ./replace.sh \"*\" aaaa bbbb"
        exit
}

if [ ! -e "$1" ]; then
    echo "please check the file $1.";
    usage
fi

if [ -z $2 -o -z $3 ]; then
    usage
fi


for f in $1; do
    sed s/$2/$3/g $f > $f.bak
    mv -f $f.bak $f
done
