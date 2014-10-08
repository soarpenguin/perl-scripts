#!/bin/bash
export PS4='$0.$LINENO+ '

AUTO_INVOKE_SUDO=yes
curdir=$(cd "$(dirname "$0")"; pwd)

function invoke_sudo() 
{
    if [ "`id -u`" != "`id -u $1`" ]; then
        echo "`whoami`:you need to be $1 privilege to run this script.";
        if [ "$AUTO_INVOKE_SUDO" == "yes" ]; then 
            echo "Invoking sudo ...";
            sudo -u "#`id -u $1`" sh -c "$2";
        fi
        exit 0;
    fi
}

uid=`id -u`
if [ $uid -ne '0' ]; then 
  # echo "Must running in root privilege.";
  # exit
  invoke_sudo root "${curdir}/$0 $@"
fi

# Check for Homebrew,
# Install if we don't have it
if test ! $(which brew); then
  echo "Installing homebrew..."
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

