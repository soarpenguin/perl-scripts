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


########## main route ############

## check ruby env
result=`which ruby`
if [ "x$result" = 'x' ]; then
    _trace "ruby is not installed, now install ruby."
    sudo brew install ruby

    if [ $? -eq 0 ]; then
        _trace "install ruby successed."
    else
        _print_fatal "install ruby failed!"
        exit 1
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
    _print_fatal "Not a git repository."
    exit 1
fi

bundle exec jekyll serve

