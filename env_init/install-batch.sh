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
            sudo -u "#`id -u $1`" bash -c "$2";
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
#------------------------------------------------------------------------------
# Prerequisites
#------------------------------------------------------------------------------
apt-get -y install aptitude

#------------------------------------------------------------------------------
# Uninstall
#------------------------------------------------------------------------------
aptitude -y purge transmission
aptitude -y purge xchat
aptitude -y purge banshee

#------------------------------------------------------------------------------
# Install
#------------------------------------------------------------------------------
# Communications
#aptitude -y install irssi
#aptitude -y install thunderbird

# Graphics
#aptitude -y install gcolor2
#aptitude -y install inkscape
#aptitude -y install gimp

# Internet
#aptitude -y install deluge

# Productivity
aptitude -y install gedit-developer-plugins
aptitude -y install gedit-plugins

# Development
aptitude -y install gcc
aptitude -y install g++
aptitude -y install ddd
aptitude -y install make
aptitude -y install valgrind
aptitude -y install autoconf
aptitude -y install automake
aptitude -y install bin86
aptitude -y install build-essential
aptitude -y update vi
aptitude -y install vim
aptitude -y install vim-gnome
aptitude -y install ctags
aptitude -y install cscope
aptitude -y install git
aptitude -y install gitk
aptitude -y install subversion
aptitude -y install mysql-server
aptitude -y install sysklogd
#aptitude -y install arduino
#aptitude -y install eclipse-jdt
#aptitude -y install python-pip
#pip install virtualenvwrapper

# System
#aptitude -y install gparted
aptitude -y install nfs-common

#------------------------------------------------------------------------------
# Firefox addons
#------------------------------------------------------------------------------
#mkdir ~/extensions
#cd ~/extensions
#declare -A addons
#addons[adblockplus]=1865
#addons[downloadstatusbar]=26
#addons[noscript]=722
#addons[ghostery]=9609
#addons[firebug]=1843
#for addon in ${!addons[@]}
#do
#    echo "Installing Firefox addon '$addon'"
#    xpi_id=${addons[$addon]}
#    wget https://addons.mozilla.org/firefox/downloads/latest/$xpi_id/addon-$xpi_id-latest.xpi
#    unzip ~/extensions/addon-$xpi_id-latest.xpi -d $xpi_id
#    rm addon-$xpi_id-latest.xpi
#    addon_id=`cat "$xpi_id/install.rdf" | grep "em:id" | head -n 1 \
#              | awk -F ">" '{print $2}' | awk -F "<" '{print $1}'`
#    mv $xpi_id $addon_id
#done
#mv ~/extensions/* /usr/lib/firefox-addons/extensions/
#rmdir ~/extensions
