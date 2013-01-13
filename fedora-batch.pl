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


my $usage = "
Usage: $script [option]...

       -f, --file             
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

my $ret;
chomp($ret = `whereis yum`);
### $ret
my @array = split(":", $ret);
### @array
if(scalar @array <= 1) {
    print "The install command \"$array[0]\" not support in your platform.\n";
    exit;
}

my $command = $array[0];
my $file; 

$ret = GetOptions( 
    'file|f=s'  => \$file,
    'help'	    => \&usage,
    'version|V' => \&version
);

if(! $ret) {
    &usage();
}

&myprint("A file must be specified.")
    unless($file);

if($> ne 0) {
    &myprint("Must run as root when install softwares.");
    exit;
}
if(! -e $file) {
    &myprint("The file \"$file\" is not exists.");
    exit;
}
##------begin install softwares-----------
my ($fd, $line);
open($fd, "<", $file);
if(! $fd) {
    myprint("Failed to open the file \"$file\". Try it again.");
    exit;
}

my $search = $command . ' search ';
my $install = $command . ' install ';
my $result;
my (@successed, @failed);
while ($line = <$fd>) {
    chomp($line);
    ### $line;
    &yesinstall("###Trying install the software of $line.");
    &yesinstall("Please waitting for a minuter......");
    $result = `$install -y $line 2>&1`;
    if($result =~ "already installed" or $result =~ "Installed:") {
        print color("blue");
        print("+++The $line installed successful.\n\n");
        print color("reset");
        push @successed, $line;
    } elsif ($result =~ "No package $line available") {
        &myprint("Check the name of software: $line\n");
        push @failed, $line;
    } else {
        &myprint("$result\n");
        push @failed, $line;
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

