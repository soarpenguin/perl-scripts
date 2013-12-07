#!/usr/bin/env perl
#
use strict;
use Term::ANSIColor;

if(-e "_vimrc") {
    #`cat _vimrc >> ~/.vimrc`;
    `cp -b _vimrc ~/.vimrc`;
    if($? != 0) {
        print color("red");
        print "cp -b _vimrc ~/.vimrc is failed!\n";
        print color("reset");
    } else {
        print "cp -b _vimrc ~/.vimrc is success!\n";
    }
} else {
    print color("red");
    print "_vimrc is not exists!\n";
    print color("reset");
}

if(-e "_bash_history") {
    #`cat _bash_history >> ~/.bash_history`;
    `cp -u _bash_history ~/.bash_history`;
    if($? != 0) {
        print color("red");
        print "cp -u _bash_history ~/.bash_history is failed!\n";
        print color("reset");
    } else {
        print "cp -u _bash_history ~/.bash_history is success!\n";
    }
} else {
    print color("red");
    print "_bash_history is not exists!\n";
    print color("reset");
}

if(-e "_bashrc") {
    #`cat _bashrc >> ~/.bashrc`;
    `cp -b _bashrc ~/.bashrc`;
    if($? != 0) {
        print color("red");
        print "cp -b _bashrc/* ~/.bashrc is failed!\n";
        print color("reset");
    } else {
        print "cp -b _bashrc/* ~/.bashrc is success!\n";
    }
} else {
    print color("red");
    print "_bashrc is not exists!\n";
    print color("reset");
}

`mkdir -p ~/.vim`;
`touch ~/.vim/systags`;
`ctags -I __THROW --file-scope=yes --langmap=c:+.h --languages=c,c++ --links=yes --c-kinds=+p -R -f ~/.vim/systags /usr/include /usr/local/include/`;

if(-e "_vim") {
    `cp -ur _vim/* ~/.vim/`;
    if($? != 0) {
        print color("red");
        print "cp -ur _vim/* ~/.vim/ is failed!\n";
        print color("reset");
    } else {
        print "cp -ur _vim/* ~/.vim/ is success!\n";
    }
} else {
    print color("red");
    print "_vim/ is not exists!\n";
    print color("reset");
}

my $ret = `whereis git`;
print $ret;
if($ret =~ "/bin/git") {
    `git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset-%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
     git config --global alias.st "status";
     git config --global alias.cfg "config";
     git config --global alias.cfgl "config --list";
     git config --global alias.rhead "reset HEAD";
     git config --global gui.encoding utf-8
     git config --global i18n.commitencoding utf-8
     git config --global i18n.logoutputencoding gbk
    `
} else {
    print color("red");
    print "please installed git first!\n";
    print color("reset");
}
