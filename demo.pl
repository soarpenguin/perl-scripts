#!/usr/bin/perl -w
#

# ***.pl -- ***********. {{{1
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Nov.14 2012
# 1}}}

BEGIN {
    use Cwd 'realpath';
    our $curdir;
    $curdir = __FILE__;
    $curdir = realpath($curdir);
    $curdir =~ s/[^\/]+$//;
    ### $curdir
    if ( -e $curdir ) {
	unshift @INC, "$curdir/lib/";
    }
}

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
#use Smart::Comments;

use Term::ANSIColor;
#print color("red"), "Stop!\n", color("reset");
#print color("green"), "Go!\n", color("reset");

my $script = basename $0;
my $myversion = '0.1.0';

my $usage = "
Usage: $script [option]...

	-h, --help 
          Display this help and exit

	-V    Display version information.
";

my $ret = GetOptions( 
	'help|h'	=> \&usage,
	'version|V' => \&version
);

if(! $ret) {
	&usage();
}

# function for signal action
sub catch_int {
	my $signame = shift;
	print color("red"), "Stoped by SIG$signame\n", color("reset");
	exit;
}
$SIG{INT} = __PACKAGE__ . "::catch_int";
$SIG{INT} = \&catch_int; # best strategy

sub usage {
	print $usage;
	exit;
}

sub version {
	print "$script version $myversion\n";
	exit;
}

