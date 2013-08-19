#!/bin/env bash

#export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }';
#curdir=$(cd `dirname $0`; pwd);

export PS4='+(${BASH_SOURCE}:${LINENO}): ${FUNCNAME[0]:+${FUNCNAME[0]}(): }'
curdir=$(cd "$(dirname "$0")"; pwd)
