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

&setup_ctags();

&backup_and_setup(\%files);

&setup_git();
#
#

$| = 1;
sub backup_and_setup {
    my $files = shift;
    my $cmd;

    if (ref($files) eq "HASH") {
        while( my($key, $value) = each(%$files)) {
            if (-e $key) {
                print("backup and setup $key => $value\n");
                $cmd = "cp -rf $value $value.bak";
                print "$cmd\n";
                #&run_cmd_api($cmd, 0);
                $cmd = "cp -rf $key $value";
                print "$cmd\n";
                #&run_cmd_api($cmd, 0);
            } else {
                print("$value is not exists, skip for setup.\n");
            }
        } 
    } elsif (ref($files) eq "ARRAY") {
        for my $file (@$files) {
            if (-e $file) {
                print("backup and setup $file\n");
            } else {
                print("$file is not exists\n");
            }
        } 
    } else {
        print "invalid parameter.\n"; 
    }
}

sub setup_ctags {
    `mkdir -p ~/.vim`;
    `touch ~/.vim/systags`;
    `ctags -I __THROW --file-scope=yes --langmap=c:+.h --languages=c,c++ --links=yes --c-kinds=+p -R -f ~/.vim/systags /usr/include /usr/local/include/`;
}

sub setup_git {
    my $ret = `whereis git`;
    print $ret;
    if($ret =~ "/bin/git") {
        `git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset-%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --";
         git config --global alias.st "status";
         git config --global alias.cfg "config";
         git config --global alias.cfgl "config --list";
         git config --global alias.rhead "reset HEAD";
         git config --global gui.encoding utf-8;
         git config --global i18n.commitencoding utf-8;
         git config --global i18n.logoutputencoding gbk;`
    } else {
        print color("red");
        print "please installed git first!\n";
        print color("reset");
    }
}

sub run_cmd_api
{
    my ($cmd, $max_retry_time) = @_;
    my $retry_time = 0;
    my $start_time;
    my $end_time;
    my $con_time;
    my %my_return;
    $my_return{desc} = "";
    
    while ($retry_time < $max_retry_time) {
        $start_time = time;
        #$my_return{desc} = `$cmd`;
        $my_return{value} = $?>>8;
        $end_time = time;
        $con_time = sprintf("%.3f", $end_time - $start_time);
        if ($my_return{value} != 0) {
            sleep(3);
            $retry_time++;
        } else {
            last;
        }
    }
    return \%my_return;
}

