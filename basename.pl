#!/usr/bin/perl -w
#

# basename.pl -- strip directory and suffix from filenames. {{{1
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Nov.14 2012
# 1}}}

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
Usage: $script NAME [SUFFIX]
  or:  $script OPTION
Print NAME with any leading directory components removed.
If specified, also remove a trailing SUFFIX.

       -h, --help       Display this help and exit
       -V, --version    Display version information.

Examples:
  $script /usr/bin/sort       Output \"sort\".
  $script include/stdio.h .h  Output \"stdio\".
";

my $ret = GetOptions( 
	'help|h'	=> \&usage,
	'version|V' => \&version
);

if(! $ret) {
	&usage();
}


if(@ARGV > 2 or @ARGV <= 0) {
    &usage();
}

&main();

sub main {
    my ($file, $suffix) = @ARGV;
    my @basename;
    ### $file
    ### $suffix

    if(! $file) {
        &usage();
    }

    if($file =~ /\//) {
        @basename = split('\/', $file);
        ### @basename
        my $scalar = @basename;
        ### $scalar
        $file = $basename[$scalar - 1];
    }

    if($suffix) {
        if($file =~ /(.*)$suffix$/) {
            $file = $1; 
        }
    }
    print "$file\n";
    ### $file 
}

sub usage {
    print color("blue");
	print $usage;
    print color("reset");
	exit;
}

sub version {
	print "$script version $myversion\n";
	exit;
}

