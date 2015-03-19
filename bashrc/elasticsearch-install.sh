#!/usr/bin/env bash

##################### function #########################
_report_err() { echo "${MYNAME}: Error: $*" >&2 ; }

# if the output is terminal, display infomation in colors.
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

function check_mkdir() {
    local dir=$1

    if [ x"$dir" == "x" ]; then
	_trace "dir string is null."
	return 1
    elif [ -d "${dir}" ]; then
	_trace "dir of ${dir} is existed, skip mkdir."
        return 0
    else
	_trace "mkdir ${dir}"
	mkdir -p ${dir}
	return $?
    fi
}

usage() {
    cat << USAGE
Usage: bash ${MYNAME} [options].

Options:
    -d, --data_dir dir    Data dir for elasticsearch.
    -h, --help            Print this help infomation.

USAGE

    exit 1
}

#
# Parses command-line options.
#  usage: _parse_options "$@" || exit $?
#
function _parse_options()
{
    declare -a argv

    while [[ $# -gt 0 ]]; do
        case $1 in
            -d|--data_dir)
                g_DATA_DIR="${2}"
            	shift 2
            	;;
            -f|--file)
		g_ELASTICSOFT="${2}"
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
}


g_ELASTICSOFT="${g_ELASTICSOFT:-elasticsearch-1.4.4.noarch.rpm}" 

_parse_options "${@}" || usage

if command -v "elasticsearch" >/dev/null; then
    _trace "elasticsearch is intalled."
    exit 0
fi

if [ -f "$g_ELASTICSOFT" ]; then
    rpm -ivh "$g_ELASTICSOFT"
    
    if [ $? -eq 0 ]; then
        _trace "Install elasticsearch success."
    else
        _print_fatal "Install elasticsearch failed, please check it yourself!"
	exit 1
    fi
fi

g_DATA_DIR="${g_DATA_DIR:-/opt/elasticsearch}"

if [ ! -d "${g_DATA_DIR}" ]; then
    mkdir -p ${g_DATA_DIR}
fi

for dir in data work logs; do
    check_mkdir "${g_DATA_DIR}/${dir}"
done

_trace "chown of dir ${g_DATA_DIR} to elasticsearch:elasticsearch"
chown -R elasticsearch:elasticsearch "${g_DATA_DIR}"

g_CONF_FILE="elasticsearch.yml"
if [ -f "${g_CONF_FILE}" ]; then
    _trace "cp yaml configure file to /etc/elasticsearch"
    cp -rf "${g_CONF_FILE}" /etc/elasticsearch/
else
    _trace "yaml configure file ${g_CONF_FILE} is not existed."
fi

if [ $? -eq 0 ]; then
    sudo /sbin/chkconfig --add elasticsearch
fi

