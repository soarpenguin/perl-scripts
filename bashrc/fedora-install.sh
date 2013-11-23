#!/bin/bash

AUTO_INVOKE_SUDO=yes;
curdir=$(dirname $(readlink -f $0));

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
    invoke_sudo root "${curdir}/$0 $@"
fi
#------------------------------------------------------------------------------
# Prerequisites
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Install
#------------------------------------------------------------------------------
# Communications
#yum -y install irssi
#yum -y install thunderbird

# Graphics
#yum -y install gcolor2
#yum -y install inkscape
#yum -y install gimp

# Internet
#yum -y install deluge

# Productivity
#yum -y install gedit-plugins

# Development
yum -y install gcc
yum -y install gcc-c++
yum -y install glibc
yum -y install glibc-common
yum -y install make
yum -y install vim
yum -y install gvim
yum -y install autoconf
yum -y install automake
yum -y install libtool
yum -y install ddd
yum -y install valgrind
yum -y install ctags
yum -y install cscope
yum -y install git
yum -y install gitk
yum -y install svn
yum -y install mysql-server

yum -y install libevent
yum -y install libevent-devel
yum -y install ncurses-devel
yum -y install perf
yum -y install sysstat
yum -y install screen
yum -y install strace
#yum -y install arduino
#yum -y install eclipse-jdt
#yum -y install python-pip

# System
#yum -y install gparted

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
