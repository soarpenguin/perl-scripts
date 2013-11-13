#!/bin/env bash

#export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }';
#curdir=$(cd `dirname $0`; pwd);

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }';
curdir=$(cd "$(dirname "$0")"; pwd);
curdir=$(dirname $(readlink -f "$0"));

#tar -cf - ./* | ( cd "${dir}" && tar -xf - )
#if [[ "${PIPESTATUS[0]}" -ne 0 || "${PIPESTATUS[1]}" -ne 0 ]]; then
#  echo "Unable to tar files to ${dir}" >&2
#fi
