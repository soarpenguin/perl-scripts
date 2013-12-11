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

# workaround for functions that don't cope with utf8 well
sub to_utf8($) {
    my ($str) = @_;
    utf8::decode($str) unless utf8::is_utf8($str);
    return $str;
}
sub readlink_utf8($) {
    my ($filename) = @_;
    return to_utf8(readlink($filename));
}
sub realpath($) { return to_utf8(Cwd::realpath(@_)); }
sub bsd_glob($) { return map {to_utf8($_)} File::Glob::bsd_glob(@_); }

# perform a code block and prevent it from blocking by using a timeout
sub do_timeout($&)
{
   my ($seconds, $code) = @_;
   local $SIG{ALRM} = sub {die "alarm clock restart executing $code"};
   alarm $seconds;  # schedule an alarm in a few seconds
   eval {
      &$code; # execute the code block or subroutine passed in
      alarm 0;  # cancel the alarm
   };
   if ($@ and $@ !~ /^alarm clock restart/) {die $@};
} # noblock()

do_timeout 10, sub { print "Hello, World!\n"};
