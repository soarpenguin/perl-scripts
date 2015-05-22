#!/usr/bin/env bash

#set -x
export PS4='+ [`basename ${BASH_SOURCE[0]}`:$LINENO ${FUNCNAME[0]} \D{%F %T} $$ ] '
PATH="$PATH:/usr/bin:/bin:/sbin:/usr/sbin"
export PATH

MYNAME="${0##*/}"
CURDIR=$(cd "$(dirname "$0")"; pwd);

g_HOST_LIST=$1
g_THREAD_NUM=300
g_PORT=22
g_LIMIT=0
TMPFILE="pipe.$$"
SSH="ssh -n -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=5 "
SCP='scp -q -r -o PasswordAuthentication=no -o StrictHostKeyChecking=no -o ConnectTimeout=5 '

RET_OK=0
RET_FAIL=1

##################### function #########################
_report_err() { echo "${MYNAME}: Error: $*" >&2 ; }

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

_usage() {
    cat << USAGE
Usage: bash ${MYNAME} [options] hostlist command.

Options:
    -c, --concurrent num  Thread Nummber for run the command at same time, default: 1.
    -s, --ssh             Use ssh authorized_keys to login without password query from DB.
    -p, --port            Use port instead of defult port:22.
    -l, --limit           Limit num for host to run when limit less then all host num.
    -h, --help            Print this help infomation.

Require:
    hostlist            Machine list filename for operation.
    command             Command string for run in every machine.

Notice:
    please check the result output under log/hostname.
USAGE

    exit $RET_OK
}

#
# Parses command-line options.
#  usage: _parse_options "$@" || exit $?
#
_parse_options()
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
            -p|--port)
                g_PORT=${2}
            	shift 2
            	;;
            -l|--limit)
                g_LIMIT=${2}
            	shift 2
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
            command -v greadlink >/dev/null 2>&1 && g_HOST_LIST=$(greadlink -f "${argv[0]}") || g_HOST_LIST=$(readlink -f "${argv[0]}")
            g_CMD="${argv[1]}"
            ;;
        0|*)
            _usage 1>&2
            return 1
	;;
    esac
}

################################## main route #################################
_parse_options "${@}" || _usage

if [ ! -e $g_HOST_LIST ]; then
    _print_fatal "machine list file $g_HOST_LIST is not exist."
    _usage
fi
if [ -d log ]; then
    rm -rf log
fi

mkdir -p log

mkfifo ${TMPFILE}
exec 9<>${TMPFILE}

#trap "rm -f ${TMPFILE}; exit" INT TERM EXIT
cleanup() { rm -f "${TMPFILE}" ; }
trap cleanup EXIT TERM EXIT;

#trap 'rm -f "${TMPFILE}"; exit $?' INT TERM EXIT
_trace "You run command: $HL_BLUE $g_CMD $NORMAL"
_trace "Notice:(${HL_RED}Ctrl+C for cancel,${NORMAL} ENTER for continue, wait for 30s continue auto.)"
read -t 30 word   # wait for 30 sec for waiting input.

for ((i=0;i<${g_THREAD_NUM};i++))
do
    echo >&9
done

unset HOST
INDEX=0

while read -r HOST
do
    HOST=${HOST#*(:space:)}
    (( INDEX++ ))
    fchar=`echo ${HOST} | cut -c -1`

    if [ "x${HOST}" == "x" ]; then
        _print_fatal "Notice: null string for hostname."
        continue
    elif [ "x$fchar" = "x#" ]; then
        host=`echo $HOST | cut -c 2-`
        _print_fatal "[$INDEX] Warn: skip ${host}"
        unset host
        continue
    fi
    unset fchar

    if [ "x$g_LIMIT" != "x0" ]; then
        if [ "$g_LIMIT" -lt "$INDEX" ]; then
            _trace "Reach limit num of $g_LIMIT"
            break
        fi
    fi

    _trace "[$INDEX] start ${HOST} ......"
    read <&9

    ping -c 1 -W 3 ${HOST} &>/dev/null

    if [ $? -ne 0 ]; then
        _print_fatal "[$INDEX] Error: ${HOST} is unreachable."
        echo >&9
        continue
    fi

    (${SSH} "${HOST}" "-p ${g_PORT}" "${g_CMD}" &>${CURDIR}/log/${HOST}; echo >&9) &
    #(${SSH} ${HOST} "ls "  &>  log/${HOST}; echo >&9) &

done < ${g_HOST_LIST}

rm -f ${TMPFILE}
#trap - INT TERM EXIT
exec 9<&-

