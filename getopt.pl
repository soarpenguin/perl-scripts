#!/usr/bin/perl -w

###################################################################
#Usage:
#	perl getopt.pl --verbose --verbose -v --more \ 
#	--lib='/lib' -l '/lib64' --f a=1 --flag b=3 --debug 3 -t ygzhu
#
#Result:
#		### $verbose: 3
#		### $more: 1
#		### $debug: 3
#		### $test: 1
#		### @libs: [
#		###          '/lib',
#		###          '/lib64'
#		###        ]
#		### %flags: {
#		###           a => '1',
#		###           b => '3'
#		###         }
###################################################################

use strict;
use File::Basename;
use Getopt::Long;

# test some modules installed or not.
BEGIN {
	if (eval "require Smart::Comments") {
		use Smart::Comments;
		print "Use Smart::Comments\n";
	} else {
		warn "No Smart::Comments";
	}
}
 
my $script = File::Basename::basename($0);
my @libs    = ();
my %flags   = ();
my ( $verbose, $all, $more, $debug, $test);
 
GetOptions(
        'verbose+'  => \$verbose,  # the '+' means the $verbose will +1 
				   #   when the -v or --verbose appear once
        'more!'     => \$more,
        'debug:i'   => \$debug,
        'lib=s'     => \@libs,
        'flag=s'    => \%flags,
        'test|t'    => \$test,
	#'all|everything|universe!' => $all,
);


use Getopt::Std qw( getopts );

my %opts;

getopts("a:dhl:p:t:uk", \%opts)
    or die &usage();

if ($opts{h}) {
    print &usage();
    exit;
}

sub usage {
    return <<'_EOC_';
Usage:
    $script [optoins]

Options:
    -h                  Print this usage.

Examples:
    $script -h
_EOC_
}
### $verbose
### $more
### $debug
### $test
### @libs;
### %flags

