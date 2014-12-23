#!/usr/bin/env bash

#set -x
export PS4='+ [`basename ${BASH_SOURCE[0]}`:$LINENO ${FUNCNAME[0]} \D{%F %T} $$ ] '

MYNAME="${0##*/}"
CURDIR=$(cd "$(dirname "$0")"; pwd)

OPENTSDBCONF="$CURDIR/opentsdb.conf"
GNUPLOT="$CURDIR/gnuplot-4.6.0"
OPENTSDB="$CURDIR/opentsdb-2.0.1.noarch.rpm"
STARTSCROPT="$CURDIR/run-opentsdb.sh"

#---------------------function----------------------
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

_fatal() {
    echo $(_hl_red '==>') "$@" >&2
    exit 1
}

_check_file_exists() {
    file=$1
    if [ x"$file" = "x" ]; then
        return 1
    else
        if [ -f "$file" ]; then
            return 0
        else
            return 1
        fi
    fi
}

software="gd-devel.x86_64"
_trace "install ${software}--------------------------------------"
yum install -y "$software" || _fatal "yum install ${software} failed, please checked it."

software="$GNUPLOT.tar.gz"
_trace "install ${software}--------------------------------------"
_check_file_exists $software || _fatal "$software is not existed"
pushd .
[ -d $GNUPLOT ] || tar -zxvf $software
cd "$GNUPLOT" && ./configure && make && make install
if [ $? -ne 0 ]; then
    _fatal "install ${software} failed, please checked it."
fi
popd

software="$OPENTSDB"
_trace "install ${software}--------------------------------------"
_check_file_exists $OPENTSDB || _fatal "$software is not existed"
rpm -ivh --nodeps $software
if [ $? -ne 0 ]; then
    _fatal "install ${software} failed, please checked it."
fi

software="$OPENTSDBCONF"
_trace "update ${software}--------------------------------------"
_check_file_exists $OPENTSDB || _fatal "$software is not existed"
cp -rf $OPENTSDBCONF /etc/opentsdb/opentsdb.conf
if [ $? -ne 0 ]; then
    _fatal "update ${software} failed, please checked it."
fi

_trace "run software opentsdb--------------------------------------"
bash ${STARTSCROPT}

