#!/usr/bin/env bash

#set -x
export PS4='+ [`basename ${BASH_SOURCE[0]}`:$LINENO ${FUNCNAME[0]} \D{%F %T} $$ ] '

AUTO_INVOKE_SUDO=yes
CURDIR=$(cd "$(dirname "$0")"; pwd)
#SCRIPT=$(basename "$0")
SCRIPT="${0##*/}"

RETFAIL=1
RETOK=0

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

_lowercase() {
    echo "$1" | tr '[A-Z]' '[a-z]'
}

_fatal_exit() {
    _print_fatal "$@"
    exit $RETFAIL
}

_invoke_sudo() {
    if [ "`id -u`" != "`id -u $1`" ]; then
        _trace "`whoami`:you need to be $1 privilege to run this script.";
        if [ "$AUTO_INVOKE_SUDO" == "yes" ]; then 
            _trace "Invoking sudo ..."
            sudo -u "#`id -u $1`" sh -c "$2"
        fi
        exit $RETOK
    fi
}

_install_zsh() {
    set -e

    if [ ! -n "$ZSH" ]; then
      ZSH=~/.oh-my-zsh
    fi

    if [ -d "$ZSH" ]; then
      echo "\033[0;33mYou already have Oh My Zsh installed.\033[0m You'll need to remove $ZSH if you want to install"
      return $RETOK
    fi

    echo "\033[0;34mCloning Oh My Zsh...\033[0m"
    hash git >/dev/null 2>&1 && env git clone --depth=1 https://github.com/robbyrussell/oh-my-zsh.git $ZSH || {
      echo "git not installed"
      exit $RETFAIL
    }

    echo "\033[0;34mLooking for an existing zsh config...\033[0m"
    if [ -f ~/.zshrc ] || [ -h ~/.zshrc ]; then
      echo "\033[0;33mFound ~/.zshrc.\033[0m \033[0;32mBacking up to ~/.zshrc.pre-oh-my-zsh\033[0m";
      mv ~/.zshrc ~/.zshrc.pre-oh-my-zsh;
    fi

    echo "\033[0;34mUsing the Oh My Zsh template file and adding it to ~/.zshrc\033[0m"
    cp $ZSH/templates/zshrc.zsh-template ~/.zshrc
    sed -i -e "/^export ZSH=/ c\\
    export ZSH=$ZSH
    " ~/.zshrc

    echo "\033[0;34mCopying your current PATH and adding it to the end of ~/.zshrc for you.\033[0m"
    sed -i -e "/export PATH=/ c\\
    export PATH=\"$PATH\"
    " ~/.zshrc

    if [ "$SHELL" != "$(which zsh)" ]; then
        echo "\033[0;34mTime to change your default shell to zsh!\033[0m"
        chsh -s `which zsh`
    fi

    echo "\033[0;32m"'         __                                     __   '"\033[0m"
    echo "\033[0;32m"'  ____  / /_     ____ ___  __  __   ____  _____/ /_  '"\033[0m"
    echo "\033[0;32m"' / __ \/ __ \   / __ `__ \/ / / /  /_  / / ___/ __ \ '"\033[0m"
    echo "\033[0;32m"'/ /_/ / / / /  / / / / / / /_/ /    / /_(__  ) / / / '"\033[0m"
    echo "\033[0;32m"'\____/_/ /_/  /_/ /_/ /_/\__, /    /___/____/_/ /_/  '"\033[0m"
    echo "\033[0;32m"'                        /____/                       ....is now installed!'"\033[0m"
    echo "\n\n \033[0;32mPlease look over the ~/.zshrc file to select plugins, themes, and options.\033[0m"
    echo "\n\n \033[0;32mp.s. Follow us at http://twitter.com/ohmyzsh.\033[0m"
    echo "\n\n \033[0;32mp.p.s. Get stickers and t-shirts at http://shop.planetargon.com.\033[0m"
    env zsh
    . ~/.zshrc
}

#################### main route ########################
OS=`uname | tr '[A-Z]' '[a-z]'`
if [ "$OS" != "darwin" ]; then
    _print_fatal "Not darwin, this script just for mac env init."
    exit $RETFAIL
fi

uid=`id -u`
if [ $uid -ne '0' ]; then 
    _invoke_sudo root "${CURDIR}/$SCRIPT $@"
fi

#chsh -s $(which zsh)
#curl -L http://install.ohmyz.sh | sh
_install_zsh || _print_fatal "Install zsh failed!"

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
brew install diffutils
brew install binutils
# Install Bash 4
brew install bash
# Install more recent versions of some OS X tools
brew tap homebrew/dupes
brew install homebrew/dupes/grep

