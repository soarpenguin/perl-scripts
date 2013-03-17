#!/usr/bin/perl -w
#
# free.pl -- display the infomation of memory. {{{1
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Nov.14 2012
# 1}}}

#             total       used       free     shared    buffers     cached
#Mem:       1024800     897528     127272          0      47684     292140
#-/+ buffers/cache:     557704     467096
#Swap:      1046524       7560    1038964

#-----run dprofpp to analyze the profile.-----
# $perl -d:DProf free.pl
# $dprofpp -u

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
#use Smart::Comments;

use Term::ANSIColor;
#print color("red"), "Stop!\n", color("reset");
#print color("green"), "Go!\n", color("reset");

my ($version, $help);
my $myvesion = "0.1.0";
my $script = basename $0;
my $meminfo = '/proc/meminfo';
my ($fd, @lines);
my ($byte, $kb, $mb, $gb, $changed);
my ($oldfmt, $count, $countflag, $sleep, $total);
my $byteshift = 10;
my ($memtotal, $memused, $memfree, $memshared, $membuf, $memcached);
my ($minus, $plus); #for (-/+ buffers/cached)
my ($lowtotal, $lowfree);
my ($hightotal, $highfree);
my $lhdetail; # display low/high memory detail info or not.
my ($swaptotal, $swapused, $swapfree);

my $usage = "
Usage: $script [-b|-k|-m|-g] [-c count] [-l] [-o] [-t] [-s delay] [-V]

       -b     Display the amount of memory in bytes.

       -c count
              Display the result count times.  Requires the -s option.

       -g     Display the amount of memory in gigabytes.

       -k     Display the amount of memory in kilobytes. This is the default.

       -l     Show detailed low and high memory statistics.

       -m     Display the amount of memory in megabytes.

       -o     Display the output in old format, the only difference being 
			  this option will disable the display of the  \"buffer adjusted\" line.

       -s     Continuously  display  the  result  delay  seconds apart. 
	          You may actually specify any floating point number for
              delay, usleep(3) is used for microsecond resolution delay times.

       -t     Display a line showing the column totals.
       
       -h, --help 
              Display this help and exit

       -V     Display version information.
";

my $ret = GetOptions( 
	'byte|b'    => \$byte,
	'k|KB'      => \$kb,
	'm|MB'      => \$mb,
	'g|GB'      => \$gb,
	'c=i'       => \$count,
	's=f'       => \$sleep,
	't'         => \$total,
	'o'         => \$oldfmt,
	'l'         => \$lhdetail,
	'help|h|?'  => \&usage,  #point to the usage();
	'version|V' => \&version
);

if(! $ret) {
    &usage();
}

#if($help or $version) {
#	&usage();
#}

if(! -e $meminfo) {
    print "Need the system file of $meminfo. Try mount /proc\n";
    die;
}

# function for signal action
sub catch_int {
    my $signame = shift;
    print color("red"), "Stoped by SIG$signame\n", color("reset");
    exit;
}
$SIG{INT} = __PACKAGE__ . "::catch_int";
$SIG{INT} = \&catch_int; # best strategy

if($byte) {
    $byteshift = 0;
    $changed = 1;
} elsif ($mb) {
    $byteshift = 20;
    $changed = 1;
} elsif ($gb) {
    $byteshift = 30;
    $changed = 1;
}
### $changed
### $byteshift

if($count and $sleep) {
    $countflag = 1;
    if($count < 0) {
        $count = -$count;
    }
} elsif ($sleep) {
    $countflag = 0;
    $count = 0;
} else {
    $countflag = 0;
    $count = 0;
    $sleep = 0;
}

### $sleep
### $count;
### $countflag;
$| = 1;
do {

    open($fd, "<", $meminfo);
    die "Failed to open the file $meminfo" unless $fd;

    @lines = <$fd>;
    close $fd;
    #print @lines;
    foreach my $line (@lines) {
        if($line =~ /\bMemTotal:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $memtotal = $line;
        } elsif ($line =~ /\bMemFree:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $memfree = $line;
        } elsif ($line =~ /\bBuffers:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $membuf = $line;
        } elsif ($line =~ /\bCached:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $memcached = $line;
        } elsif ($line =~ /\bHighTotal:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $hightotal = $line;
        } elsif ($line =~ /\bHighFree:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $highfree = $line;
        } elsif ($line =~ /\bLowTotal:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $lowtotal = $line;
        } elsif ($line =~ /\bLowFree:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $lowfree = $line;
        } elsif ($line =~ /\bSwapTotal:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $swaptotal = $line;
        } elsif ($line =~ /\bSwapFree:(\s+)(\d+)/i) {
            $line =~ s/[^0-9]//g;
            $swapfree = $line;
            last;
        }
    }

    # I'm not sure the $2 will influence the profile. so not use it.
    #foreach my $line (@lines) {
    #	if($line =~ /\bMemTotal:(\s+)(\d+)/) {
    #		$memtotal = $2;
    #	} elsif ($line =~ /\bMemFree:(\s+)(\d+)/) {
    #		$memfree = $2;
    #	} elsif ($line =~ /\bBuffers:(\s+)(\d+)/) {
    #		$membuf = $2;
    #	} elsif ($line =~ /\bCached:(\s+)(\d+)/) {
    #		$memcached = $2;
    #	} elsif ($line =~ /\bHighTotal:(\s+)(\d+)/) {
    #		$hightotal = $2;
    #	} elsif ($line =~ /\bHighFree:(\s+)(\d+)/) {
    #		$highfree = $2;
    #	} elsif ($line =~ /\bLowTotal:(\s+)(\d+)/) {
    #		$lowtotal = $2;
    #	} elsif ($line =~ /\bLowFree:(\s+)(\d+)/) {
    #		$lowfree = $2;
    #	} elsif ($line =~ /\bSwapTotal:(\s+)(\d+)/) {
    #		$swaptotal = $2;
    #	} elsif ($line =~ /\bSwapFree:(\s+)(\d+)/) {
    #		$swapfree = $2;
    #		last;
    #	}
    #}

    $memshared = 0;
    $memused = $memtotal - $memfree;
    $swapused = $swaptotal - $swapfree;
    $minus = $memused - $membuf - $memcached;
    $plus = $memfree + $membuf + $memcached;

    if($changed) {
        $memtotal = &sizeshift($memtotal, $byteshift); # mem total/used/free/buffer/cached
        $memused = &sizeshift($memused, $byteshift);
        $memfree = &sizeshift($memfree, $byteshift);
        $membuf = &sizeshift($membuf, $byteshift);
        $memcached = &sizeshift($memcached, $byteshift);
        $lowtotal = &sizeshift($lowtotal, $byteshift);	# low total/free
        $lowfree = &sizeshift($lowfree, $byteshift);
        $hightotal = &sizeshift($hightotal, $byteshift);  #high total/free
        $highfree = &sizeshift($highfree, $byteshift);
        $minus = &sizeshift($minus, $byteshift);	# minus/plus buffer/cached
        $plus = &sizeshift($plus, $byteshift);
        $swaptotal = &sizeshift($swaptotal, $byteshift); # swap total/used/free
        $swapused = &sizeshift($swapused, $byteshift);
        $swapfree = &sizeshift($swapfree, $byteshift);
    }

    print color("blue"); # use blue color for infomation head.
    printf("%18s %10s %10s %10s %10s %10s\n", "total", "used", 
        "free", "shared", "buffers", "cached");
    print color("reset"); # reset the default color.

    printf("%-6s %11d %10d %10d %10d %10d %10d\n", "Mem:", $memtotal, $memused,
        $memfree, $memshared, $membuf, $memcached);

    # diplay the detail of low/high memory infomation
    if($lhdetail) {
        printf("%-6s %11d %10d %10d\n", "Low:", $lowtotal, $lowtotal-$lowfree, $lowfree);
        printf("%-6s %11d %10d %10d\n", "High:", $hightotal, $hightotal-$highfree, $highfree);
    }

    if(! $oldfmt) {
        printf("%18s %10d %10d\n", "-/+ buffers/cache:", $minus, $plus);
    }

    printf("%-6s %11d %10d %10d\n", "Swap:", $swaptotal, $swapused, $swapfree);

    if($total) {
        printf("%-6s %11d %10d %10d\n", "Total:", $memtotal + $swaptotal, 
            $memused+$swapused, $memfree+$swapfree);
    }

    if($countflag) {
        $count -= 1;
        if($count <= 0) {
            $sleep = 0;
        }
    }

    if($sleep) {
        select(undef, undef, undef, $sleep); # use "select" for "usleep".
        print "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++\n"
    }

} while ($sleep);

sub usage {
    print "$script version $myvesion\n";
    print $usage;
    exit;
}

sub version {
    print "$script version $myvesion\n";
    exit;
}

sub sizeshift {
    my ($size, $shift) = @_;

    return (($size << 10) >> $shift);
}

### $byteshift
### $memtotal
### $memfree
### $membuf
### $memcached
