#!/usr/bin/env perl
#
use strict;
use Term::ANSIColor;
our $EOS_OK = 0;
our $ERR_FILE_EXIST = 1;
our $ERR_OPERATION  = 2;
our $EOS_ERR = 3;
my $result = 0;

$result = check_setup_file("_vimrc", '~/.vimrc');

$result = check_setup_file("_bash_history", '~/.bash_history');

$result = check_setup_file("_bashrc", '~/.bashrc');

$result = check_setup_file("_screenrc", '~/.screenrc');

my $cmd = "mkdir -p ~/.vim";
$result = run_and_check_result($cmd);
$cmd = "touch ~/.vim/systags";
$result = run_and_check_result($cmd);
$cmd = "ctags -I __THROW --file-scope=yes --langmap=c:+.h --languages=c,c++ --links=yes --c-kinds=+p -R -f ~/.vim/systags /usr/include /usr/local/include/";
$result = run_and_check_result($cmd);

$result = check_setup_dir("_vim/", '~/.vim');

$cmd = "whereis git";
$result = run_cmd_api($cmd, 1);
if($result->{return_value} == 0 and $result->{desc} =~ /\w+\/git/) {
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

sub run_and_check_result
{
    my ($cmd) = @_;
    my ($result, $ret);

    $ret = run_cmd_api($cmd, 1);
    if ($ret->{return_value} != 0) {
        print color("red");
        print "run $cmd failed! $ret->{desc}\n";
        print color("reset"); 
        $result = $EOS_ERR;
    } else {
        print color("blue");
        print "run $cmd successed!\n";
        print color("reset");
        $result = $EOS_OK;
    }
    return $result;
}

sub check_setup_dir
{
    my ($src, $dest) = @_;
    my $result = 0;
    my ($cmd, $ret);

    if (! -d $src) {
        print color("red");
        print "dir of $src is not exists!\n";
        print color("reset");
        $result = $ERR_FILE_EXIST;
    } else {
        $cmd = "cp -ur $src/* $dest";
        $ret = run_cmd_api($cmd, 1);
        if ($ret->{return_value} != 0) {
            print color("red");
            print "run $cmd failed!\n";
            print color("reset");
            $result = $ERR_OPERATION;
        } else {
            print color("blue");
            print "run $cmd successed!\n";
            print color("reset"); 
            $result = $EOS_OK;
        }
    }
    return $result;
}

sub check_setup_file
{
    my ($src, $dest) = @_;
    my $result = 0;
    my ($cmd, $ret);

    if (! -e $src) {
        print color("red");
        print "file of $src is not exists!\n";
        print color("reset");
        $result = $ERR_FILE_EXIST;
    } else {
        $cmd = "cp -b $src $dest";
        $ret = run_cmd_api($cmd, 1);
        if ($ret->{return_value} != 0) {
            print color("red");
            print "run $cmd failed!\n";
            print color("reset");
            $result = $ERR_OPERATION;
        } else {
            print color("blue");
            print "run $cmd successed!\n";
            print color("reset"); 
            $result = $EOS_OK;
        }
    }
    return $result;
}

sub run_cmd_api 
{
    my ($cmd, $max_retry_time) = @_;
    my $retry_time = 0;
    my $start_time;
    my $end_time;
    my $con_time;
    my %return_hash;
    $return_hash{desc} = "";
    while ($retry_time < $max_retry_time) {
        $start_time = time;
        $return_hash{desc} = `$cmd`;
        $return_hash{return_value} = $?>>8;
        $end_time = time;
        $con_time = sprintf("%.3f", $end_time - $start_time);
        if ($return_hash{return_value} != 0) {
            sleep(3);
            $retry_time++;
        } else {
            last;
        }
    }

    return \%return_hash;
}
