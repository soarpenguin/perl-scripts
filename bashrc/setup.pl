#!/usr/bin/env perl
#
use strict;
use Term::ANSIColor;

if(-e "_vimrc") {
    `cat _vimrc >> ~/.vimrc`;
} else {
    print color("red");
    print "_vimrc is not exists!\n";
    print color("reset");
}

if(-e "_bash_history") {
    `cat _bash_history >> ~/.bash_history`;
} else {
    print color("red");
    print "_bash_history is not exists!\n";
    print color("reset");
}

if(-e "_bashrc") {
    `cat _bashrc >> ~/.bashrc`;
} else {
    print color("red");
    print "_bashrc is not exists!\n";
    print color("reset");
}

my $ret = `whereis git`;
print $ret;
if($ret =~ "/bin/git") {
    `git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset-%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
     git config --global alias.st "status";
     git config --global alias.cfg "config";
     git config --global alias.cfgl "config --list";
    `
} else {
    print color("red");
    print "please installed git first!\n";
    print color("reset");
}

