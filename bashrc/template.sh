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

#'-t FD'
#     True if file descriptor FD is open and refers to a terminal.

# colour macros
if [ -t 1 ]
then
    BLACK="$( echo -e "\e[30m" )"
    RED="$( echo -e "\e[31m" )"
    GREEN="$( echo -e "\e[32m" )"
    YELLOW="$( echo -e "\e[33m" )"
    BLUE="$( echo -e "\e[34m" )"
    PURPLE="$( echo -e "\e[35m" )"
    CYAN="$( echo -e "\e[36m" )"
    WHITE="$( echo -e "\e[37m" )"

    HL_BLACK="$( echo -e "\e[30;1m" )"
    HL_RED="$( echo -e "\e[31;1m" )"
    HL_GREEN="$( echo -e "\e[32;1m" )"
    HL_YELLOW="$( echo -e "\e[33;1m" )"
    HL_BLUE="$( echo -e "\e[34;1m" )"
    HL_PURPLE="$( echo -e "\e[35;1m" )"
    HL_CYAN="$( echo -e "\e[36;1m" )"
    HL_WHITE="$( echo -e "\e[37;1m" )"

    BG_BLACK="$( echo -e "\e[40m" )"
    BG_RED="$( echo -e "\e[41m" )"
    BG_GREEN="$( echo -e "\e[42m" )"
    BG_YELLOW="$( echo -e "\e[43m" )"
    BG_BLUE="$( echo -e "\e[44m" )"
    BG_PURPLE="$( echo -e "\e[45m" )"
    BG_CYAN="$( echo -e "\e[46m" )"
    BG_WHITE="$( echo -e "\e[47m" )"

    NORMAL="$( echo -e "\e[0m" )"
fi

_black()  { echo "$BLACK""$@""$NORMAL";}
_red()    { echo "$RED""$@""$NORMAL";}
_green()  { echo "$GREEN""$@""$NORMAL";}
_yellow() { echo "$YELLOW""$@""$NORMAL";}
_blue()   { echo "$BLUE""$@""$NORMAL";}
_purple() { echo "$PURPLE""$@""$NORMAL";}
_cyan()   { echo "$CYAN""$@""$NORMAL";}
_white()  { echo "$WHITE""$@""$NORMAL";}

_hl_black()  { echo "$HL_BLACK""$@""$NORMAL";}
_hl_red()    { echo "$HL_RED""$@""$NORMAL";}
_hl_green()  { echo "$HL_GREEN""$@""$NORMAL";}
_hl_yellow() { echo "$HL_YELLOW""$@""$NORMAL";}
_hl_blue()   { echo "$HL_BLUE""$@""$NORMAL";}
_hl_purple() { echo "$HL_PURPLE""$@""$NORMAL";}
_hl_cyan()   { echo "$HL_CYAN""$@""$NORMAL";}
_hl_white()  { echo "$HL_WHITE""$@""$NORMAL";}

_bg_black()  { echo "$BG_BLACK""$@""$NORMAL";}
_bg_red()    { echo "$BG_RED""$@""$NORMAL";}
_bg_green()  { echo "$BG_GREEN""$@""$NORMAL";}
_bg_yellow() { echo "$BG_YELLOW""$@""$NORMAL";}
_bg_blue()   { echo "$BG_BLUE""$@""$NORMAL";}
_bg_purple() { echo "$BG_PURPLE""$@""$NORMAL";}
_bg_cyan()   { echo "$BG_CYAN""$@""$NORMAL";}
_bg_white()  { echo "$BG_WHITE""$@""$NORMAL";}

# helper functions
_message() {
    echo "$@" >&2
}

_trace() {
    echo $(_hl_blue '  ->') "$@" >&2
}

_notice() {
    echo $(_hl_green '==>') "$@" >&2
}

_warning() {
    echo $(_hl_yellow '==> WARNING:') "$@" >&2
}

_fatal() {
    echo $(_hl_red '==> ERROR:') "$@" >&2
    exit 1
}

_print_fatal() {
    echo $(_hl_red '==> ERROR:') "$@" >&2
}

#_print_fatal "Command '$cmd' does not exist!"
