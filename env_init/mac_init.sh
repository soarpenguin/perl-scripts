#!/usr/bin/env bash

#set -x
export PS4='+ [`basename ${BASH_SOURCE[0]}`:$LINENO ${FUNCNAME[0]} \D{%F %T} $$ ] '

AUTO_INVOKE_SUDO=yes
curdir=$(cd "$(dirname "$0")"; pwd)
#script=$(basename "$0")
script="${0##*/}"

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

function invoke_sudo() {
    if [ "`id -u`" != "`id -u $1`" ]; then
        _trace "`whoami`:you need to be $1 privilege to run this script.";
        if [ "$AUTO_INVOKE_SUDO" == "yes" ]; then 
            _trace "Invoking sudo ...";
            sudo -u "#`id -u $1`" sh -c "$2";
        fi
        exit 0;
    fi
}

#################### main route ########################
OS=`uname`
OS=`lowercase $OS`
if [ "$OS" != "darwin" ]; then
    _print_fatal "Not darwin, this script just for mac env init."
    exit 1
fi


uid=`id -u`
if [ $uid -ne '0' ]; then 
    invoke_sudo root "${curdir}/$script $@"
fi

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
    _trace "Installing homebrew..."
    ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

# Update homebrew recipes
brew update
# Install GNU core utilities (those that come with OS X are outdated)
brew install coreutils
# Install GNU `find`, `locate`, `updatedb`, and `xargs`, g-prefixed
brew install findutils
# Install Bash 4
brew install bash
# Install more recent versions of some OS X tools
brew tap homebrew/dupes
brew install homebrew/dupes/grep

