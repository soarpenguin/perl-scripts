#!/usr/bin/env bash

export PS4='+ [\D{%F %T} \W ${BASH_SOURCE[0]}:$LINENO ${FUNCNAME[0]:-MAIN}]\$ '

MYNAME=`echo $0 | sed -e 's/\.[^\.]+$//'`
PREFIX=$(dirname `readlink -f $0`)/..
BINDIR=$PREFIX/bin
DATADIR=$PREFIX/data
LOGDIR=$PREFIX/log
CONFDIR=$PREFIX/conf

blacklist_conf=$CONFDIR/blacklist.conf

datetime=`date +%Y%m%d%H%M`
this_data_dir=$DATADIR/$datetime
mkdir $this_data_dir
rm $DATADIR/current
ln -svf $this_data_dir $DATADIR/current

list_all=$this_data_dir/list_all
list_todo=$this_data_dir/list_todo
list_ignore=$this_data_dir/list_ignore
checksum=$this_data_dir/checksum

cd
find . -type f -or -type l > $list_all
egrep -v -f $blacklist_conf $list_all > $list_todo
egrep    -f $blacklist_conf $list_all > $list_ignore

cat $list_todo | xargs nice -19 md5sum > $checksum 2>$checksum.err

wc -l $checksum $list_ignore $checksum.err
wc -l $list_all
