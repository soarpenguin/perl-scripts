#!/usr/bin/env bash

#set -x
export PS4='+ [`basename ${BASH_SOURCE[0]}`:$LINENO ${FUNCNAME[0]} \D{%F %T} $$ ] '
#PATH="$PATH:/usr/bin:/bin:/sbin:/usr/sbin"
#export PATH

MYNAME="${0##*/}"
curdir=$(cd "$(dirname "$0")"; pwd);

OS=`uname`
OS=$(echo "$OS" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/")
g_LIST=$1

##################### function #########################
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

function lowercase() {
    echo "$1" | sed "y/ABCDEFGHIJKLMNOPQRSTUVWXYZ/abcdefghijklmnopqrstuvwxyz/"
}

_readlink() {
    file=$1

    if [ "x$file" = "x" ]; then
        echo ""
    fi

    if [ "$OS" = "darwin" ]; then
        filename="${file##*/}"
        filedir=$(cd "$(dirname "$file")"; pwd);

        echo "$filedir/$filename"
    else
        echo $(readlink -f $file)
    fi

}

usage() {
    cat << USAGE
Usage: bash ${MYNAME} [options] software.

Options:
    -h, --help            Print this help infomation.

Require:
    softlist            Software list filename for operation.

USAGE

    exit 1
}

#
# Parses command-line options.
#  usage: parse_options "$@" || exit $?
#
function parse_options()
{
    declare -a argv

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
            	usage
            	exit
            	;;
            --)
            	shift
                argv=("${argv[@]}" "${@}")
            	break
            	;;
            -*)
            	_print_fatal "command line: unrecognized option $1" >&2
            	return 1
            	;;
            *)
                argv=("${argv[@]}" "${1}")
                shift
                ;;
        esac
    done

    case ${#argv[@]} in
        1)
            g_LIST=$(_readlink "${argv[0]}")
            ;;
        0|*)
            usage 1>&2
            return 1
	;;
    esac
}

AUTO_INVOKE_SUDO=yes
function invoke_sudo() 
{
    if [ "`id -u`" != "`id -u $1`" ]; then
        _trace "`whoami`:you need to be $1 privilege to run this script.";
        if [ "$AUTO_INVOKE_SUDO" == "yes" ]; then 
            _trace "Invoking sudo ...";
            sudo -u "#`id -u $1`" bash -c "$2";
        fi
        if [ "$OS" != "darwin" ]; then
            exit 0;
        fi
    fi
}

uid=`id -u`
if [ $uid -ne '0' ]; then 
    invoke_sudo root "${curdir}/$0 $@"
fi

################################## main route #################################
parse_options "${@}" || usage

if [ ! -e $g_LIST ]; then
    _print_fatal "Software list file $g_LIST is not exist."
    usage
fi


for cmd in apt-get yum port brew pacman; do
    if command -v $cmd >/dev/null; then
        package_manager="$cmd"
        break
    fi
done

if [ x"$package_manager" = "x" ]; then
    _print_fatal "Get package manager failed."
    exit 1
fi

unset SOFT
while read -r SOFT
do
    if [ "x$SOFT" = "x" ]; then
        _print_fatal "null string for software."
        continue
    fi

    echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
    _trace "start install ${SOFT} ......"

    CMD="$package_manager install -y $SOFT"
    $CMD

    if [ $? -ne 0 ]; then
        _print_fatal "Error: $SOFT is install failed."
        exit 1
    fi

done < ${g_LIST}

