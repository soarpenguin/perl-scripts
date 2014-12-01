#!/bin/bash

#set -x
export PS4='+ [`basename ${BASH_SOURCE[0]}`:$LINENO ${FUNCNAME[0]} \D{%F %T} $$ ] '
PATH="$PATH:/usr/bin:/bin:/sbin:/usr/sbin"
export PATH

MYNAME="${0##*/}"
curdir=$(cd "$(dirname "$0")"; pwd);

g_HOST_LIST=$1
g_THREAD_NUM=300
tmp_file="pipe.$$"
SSH="ssh -n -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=5 "
SCP='scp -q -r -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=5 '

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

usage() {
    cat << USAGE
Usage: bash ${MYNAME} [options] hostlist command.

Options:
    -c, --concurrent num  Thread Nummber for run the command at same time, default: 1.
    -s, --ssh             Use ssh authorized_keys to login without password query from DB.
    -h, --help            Print this help infomation.

Require:
    hostlist            Machine list filename for operation.
    command             Command string for run in every machine.

Notice:
    please check the result output under log/hostname.
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
            -c|--concurrent)
                g_THREAD_NUM="${2}"
            	shift 2
            	;;
            -s|--ssh)
                g_NOPASSWD=1
            	shift
            	;;
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
        2)
            g_HOST_LIST=$(readlink -f "${argv[0]}")
            g_CMD="${argv[1]}"
            ;;
        0|*)
            usage 1>&2
            return 1
	;;
    esac
}

################################## main route #################################
parse_options "${@}" || usage

if [ ! -e $g_HOST_LIST ]; then
    _print_fatal "machine list file $g_HOST_LIST is not exist."
    usage
fi
if [ -d log ]; then
    rm -rf log
fi

mkdir -p log

mkfifo ${tmp_file}
exec 9<>${tmp_file}

#trap "rm -f ${tmp_file}; exit" INT TERM EXIT  
cleanup() { rm -f "${tmp_file}" ; }
trap cleanup EXIT TERM EXIT;

#trap 'rm -f "${tmp_file}"; exit $?' INT TERM EXIT

for ((i=0;i<${g_THREAD_NUM};i++))
do
    echo >&9
done

unset HOST
while read -r HOST
do
    _trace "start  ${HOST} ......"
    read <&9

    port=22
    (${SSH} "${HOST}" "-p ${port}" "${g_CMD}" &>${curdir}/log/${HOST}; echo >&9) &
    #(${SSH} ${HOST} "ls "  &>  log/${HOST}; echo >&9) &

done < ${g_HOST_LIST}

rm -f ${tmp_file}
#trap - INT TERM EXIT
exec 9<&-

