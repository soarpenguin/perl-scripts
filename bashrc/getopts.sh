#!/usr/bin/env bash

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'

while getopts "cn" opt; do
    case $opt in
        c)
            let Type=1
            ;;
        n)
            let Type=2
            ;;
        *)
            let Type=3
            ;;
    esac
done

while getopts ":a:" opt; do
  case $opt in
    a)
      echo "-a was triggered, Parameter: $OPTARG" >&2
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

echo "The type is $Type";

function usage
{
        echo "bash $0 --name=NAME --workspace=WORKSPACE --base=BASE --level=LEVEL --table=TABLE [--help|-h]"
}

topdir=`dirname $0`;
ARGS=`getopt -a -o w:b:l:t:h -l name:,workspace:,base:,level:,table:,help -- "$@"`
[ $? -ne 0 ] && usage
eval set -- "${ARGS}"

while true  
do
        case "$1" in
        --name)
                name="$2"
                shift 2
                ;;
        --workspace)
                workspace="${2}"
                shift 2
                ;;
        --base)
                base="$2"
                shift 2
                ;;
        --level)
                level="$2"
                shift 2
                ;;
        --table)
                table="$2"
                shift 2
                ;;
        --help|-h)
                echo "unknown arg: $1"
                usage
                exit 1
                ;;
        --)
                shift
                break
                ;;
        esac
done
