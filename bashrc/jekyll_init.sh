#!/usr/bin/env bash

####function
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

_fatal() {
    echo $(_hl_red '==>') "$@" >&2
    exit 1
}

########## main route ############
for cmd in apt-get yum port brew pacman; do
    if command -v $cmd >/dev/null; then
        package_manager="$cmd"
        break
    fi
done

## check ruby env
result=`which ruby`
if [ "x$result" = 'x' ]; then
    _trace "ruby is not installed, now install ruby."
    sudo $package_manager install ruby
    sudo $package_manager install rubygems

    if [ $? -eq 0 ]; then
        _trace "install ruby successed."
    else
        _fatal "install ruby failed!"
    fi
else
    version=`ruby --version`
    _trace "ruby is installed. version: $version"
fi

_trace "add source of ruby https://ruby.taobao.org/."
result=`gem sources --remove https://rubygems.org/`
result=`gem sources -a https://ruby.taobao.org/`
_trace "gem suouces add result: $result"
#gem sources -l

_trace "gem install bundler."
gem install bundler

if [ -d ".git/" ]; then
    bundle install
else
    _fatal "Not a git repository."
fi

bundle exec jekyll serve

