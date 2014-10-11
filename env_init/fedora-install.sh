#!/bin/bash

AUTO_INVOKE_SUDO=yes;
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
    invoke_sudo root "${curdir}/$0 $@"
fi

for cmd in apt-get yum port brew pacman; do
    if command -v $cmd >/dev/null; then
        package_manager="$cmd"
        break
    fi
done

if [ x"$package_manager" = "x" ]; then
    echo "Get install cmd failed."
    exit 1
fi

#------------------------------------------------------------------------------
# Prerequisites
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Install
#------------------------------------------------------------------------------
# Communications
#$package_manager -y install irssi
#$package_manager -y install thunderbird

# Graphics
#$package_manager -y install gcolor2
#$package_manager -y install inkscape
#$package_manager -y install gimp

# Internet
#$package_manager -y install deluge

# Productivity
#$package_manager -y install gedit-plugins

# Development
$package_manager -y install gcc
$package_manager -y install gcc-c++
$package_manager -y install glibc
$package_manager -y install glibc-common
$package_manager -y install make
$package_manager -y update vi
$package_manager -y install vim
$package_manager -y install gvim
$package_manager -y install autoconf
$package_manager -y install automake
$package_manager -y install libtool
$package_manager -y install ddd
$package_manager -y install valgrind
$package_manager -y install ctags
$package_manager -y install cscope
$package_manager -y install git
$package_manager -y install gitk
$package_manager -y install svn
$package_manager -y install mysql-server

$package_manager -y install libevent
$package_manager -y install libevent-devel
$package_manager -y install ncurses-devel
$package_manager -y install perf
$package_manager -y install sysstat
$package_manager -y install screen
$package_manager -y install strace
#$package_manager -y install arduino
#$package_manager -y install eclipse-jdt
#$package_manager -y install python-pip

# System
#$package_manager -y install gparted

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
