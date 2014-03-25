#!/usr/bin/env perl
#
use strict;
use Term::ANSIColor;

my %files = (
    "_vimrc" => "~/.vimrc",
    "_bash_history" => "~/.bash_history",
    "_bashrc" => "~/.bashrc",
    "_vim" => "~/.vim"
);

&backup_and_setup(\%files);

#
#`mkdir -p ~/.vim`;
#`touch ~/.vim/systags`;
#`ctags -I __THROW --file-scope=yes --langmap=c:+.h --languages=c,c++ --links=yes --c-kinds=+p -R -f ~/.vim/systags /usr/include /usr/local/include/`;
#

#my $ret = `whereis git`;
#print $ret;
#if($ret =~ "/bin/git") {
#    `git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset-%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
#     git config --global alias.st "status";
#     git config --global alias.cfg "config";
#     git config --global alias.cfgl "config --list";
#     git config --global alias.rhead "reset HEAD";
#     git config --global gui.encoding utf-8
#     git config --global i18n.commitencoding utf-8
#     git config --global i18n.logoutputencoding gbk
#    `
#} else {
#    print color("red");
#    print "please installed git first!\n";
#    print color("reset");
#}

sub backup_and_setup {
    my $files = shift;

    print ref($files) . "\n";
    #if ()
    #for my $file (@files) {
    #    if (-e $file) {
    #        print("backup and setup $file\n");
    #    } else {
    #        print("$file is not exists\n");
    #    }
    #}
}
