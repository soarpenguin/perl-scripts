#!/usr/bin/perl
#

# mpstat.pl -- mpstat command implemented use perl. {{{1
#   get infomation from /proc system.
#   the main file for system info is:
#    /proc/stat /proc/uptime /proc/meminfo etc.
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Feb.26 2013
# 1}}}

use strict;
use File::Basename;
use Getopt::Std qw( getopts );
use Smart::Comments;
use POSIX ();

use Term::ANSIColor;

my %opts;
my ($interval, $count); 
my $script = File::Basename::basename($0);
my $version = "0.0.1";
my $STAT = "/proc/stat";
my $INTERRUPTS = "/proc/interrupts";

$|++;
if(@ARGV < 1) {
    print &usage();
    exit;
}

getopts("hAI:uP:V", \%opts)
    or die print &usage();

## %opts
if ($opts{h}) {
    print &usage();
    exit;
} elsif ($opts{V}) {
    &version($script, $version);
    exit;
}

if (@ARGV > 0) {
    ($interval, $count) = @ARGV;
}

my $hz = POSIX::sysconf( &POSIX::_SC_CLK_TCK ) || 100;
### $hz
my $nr = &get_cpu_nr();
### $nr
## $interval
## $count

sub usage {
    return <<'_EOC_';
Usage:
    mpstat.pl [ options ] [ <interval> [ <count> ] ]
Options are:
    [ -A ] [ -I { SUM | CPU | SCPU | ALL } ] [ -u ]
    [ -P { <cpu> [,...] | ON | ALL } ] [ -V ]

Examples:
    mpstat.pl -h
    mpstat.pl 2 5
    mpstat.pl -P ALL 2 5
_EOC_
}

sub version {
    my ($program, $version);
    ($program, $version) = @_;

    print "$program version $version\n";
    print "(C) soarpenguin (soarpenguin<at>gmail.com)\n";
}

sub init_nls {
    setlocale(&POSIX::LC_MESSAGES, "");
    setlocale(&POSIX::LC_CTYPE, "");
    setlocale(&POSIX::LC_TIME, "");
    setlocale(&POSIX::LC_NUMERIC, "");
}

sub get_cpu_nr {
    my $cpustat = "/proc/stat";
    my $nr = -1;

    if(! -e $cpustat) {
        print "";
        return $nr + 1;
    }

    open(my $fd, "<", $cpustat);
    if(! $fd) {
        return $nr + 1;
    }

    while(<$fd>) {
        if($_ =~ /cpu/) {
            $nr++
        } else {
            last;
        }
    }

    close($fd);
    return $nr;
}
