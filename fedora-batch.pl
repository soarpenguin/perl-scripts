#!/usr/bin/env perl
#

# fedora-batch.pl -- batch command for install softwares. {{{1
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Jan.13 2011
# 1}}}

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
#use Smart::Comments;
use File::Spec::Functions;
use POSIX qw(strftime);
use Cwd;

use Term::ANSIColor;
#print color("red"), "Stop!\n", color("reset");
#print color("green"), "Go!\n", color("reset");

my $script = basename $0;
my $myversion = '0.1.0';

&clrscr();

my $usage = "
Usage: $script [option]...

       -c <cmd>, --command <cmd>
            The command for install software. 
            such as: yum, apt-get, aptitude 

       -f <file>, --file <file>
            File contains the softwares need to be installed. 
            One software a line. like: 
                gvim
                git

       -h, --help 
            Display this help and exit

       -V,  --version  
            output version information and exit
";

if ($^O ne 'linux') {
    die "Only linux is supported but I am on $^O.\n";
}

my ($file, $command, $ret); 

$ret = GetOptions( 
    'command|c=s' => \$command,
    'file|f=s'  => \$file,
    'help'	    => \&usage,
    'version|V' => \&version
);

if(! $ret) {
    &usage();
}

my @commands = ("yum", "apt-get", "aptitude");
my (@array, $found);

if(! $command) {
    foreach my $cmd (@commands) {
        chomp($ret = `whereis $cmd`);
        @array = split(":", $ret);
        if(scalar @array <= 1) {
            $found = 0;
        } else {
            $command = $array[0];
            $found = 1;
            last;
        }
    }
    if(! $found) {
        print "Follow install commands not supported in your platform.\n";
        print "++\t@commands\n";
        print "Please choose a supported command for try again!\n";
        exit;
    }
} else {
    chomp($ret = `whereis $command`);
    @array = split(":", $ret);
    ### @array
    if(scalar @array <= 1) {
        print "The install command \"$array[0]\" not support in your platform.\n";
        exit;
    }
    $command = $array[0];
}

if(! $file) {
    if(@ARGV > 0) {
        $file = $ARGV[0];
    } else {
        &myprint("A file must be specified.");
        &usage();
    }
}

if($> ne 0) {
    &myprint("Must run as root when install softwares.");
    exit;
}
if(! -e $file) {
    &myprint("The file \"$file\" is not exists.");
    exit;
}
##------begin install softwares-----------
$| = 1;
my ($fd, $line);
open($fd, "<", $file);
if(! $fd) {
    &myprint("Failed to open the file \"$file\". Try it again.");
    exit;
}

my $search = $command . ' search ';
my $install = $command . ' -y install ';
my ($result, $etimes);
$etimes = 0;
my (@successed, @failed);
print "Start install software: use the command \"$command\"\n";
print "==========================================\n";
while ($line = <$fd>) {
    chomp($line);
    ### $line;
    if($line =~ /(^(\s)*#)|(^$)|(^(\s)*\/\/)/) {
        next;
    }
    &yesinstall("###Trying install the software of $line.");
    &yesinstall("Please waitting for a minuter......");
    $result = `$install $line 2>&1`;
    if($result =~ "already installed" or $result =~ "Installed:") {
        print color("blue");
        print("+++The $line installed successful.\n\n");
        print color("reset");
        push @successed, $line;
        $etimes = 0;
    } elsif ($result =~ "No package $line available") {
        &myprint("Check the name of software: $line\n");
        push @failed, $line;
        if(++$etimes > 5) {
            last;
        }
    } else {
        &myprint("$result\n");
        push @failed, $line;
        if(++$etimes > 5) {
            last;
        }
    }
    ### $result
}

## Summary for installed software.
print "Transaction Summary\n";
print "==========================================\nInstalled:\n";
if(scalar @successed > 0) {
    print color("blue");
    foreach my $element (@successed) {
        print "   $element\n";
    }
    print color("reset");
}

if(scalar @failed > 0) {
    print "\nFail Installed:\n";
    print color("red");
    foreach my $element (@failed) {
        print "   $element\n";
    }
    print color("reset");
}

#-----------------------------------------------------
#
sub usage {
    print $usage;
    exit;
}

sub version {
    print "$script version $myversion\n";
    &usage();
}

sub mydie {
    print color("red");
    print("@_ \n");
    print color("reset");
    &usage();
}

sub myprint {
    print color("red");
    print("@_ \n");
    print color("reset");
}

sub yesinstall {
    print color("green");
    print("@_ \n");
    print color("reset");
}

# Esc[2JEsc[1;1H    - Clear screen and move cursor to 1,1 (upper left) pos.
#define clrscr()              puts ("\e[2J\e[1;1H")
sub clrscr {
    print "\e[2J\e[1;1H";
}
