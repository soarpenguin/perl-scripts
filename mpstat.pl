#!/usr/bin/env perl
#

# mpstat.pl -- mpstat command implemented use perl. {{{1
#   get infomation from /proc system.
#   the major file for system info is:
#    /proc/stat /proc/uptime /proc/meminfo etc.
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Feb.26 2013
# 1}}}

use strict;
use File::Basename;
use Getopt::Std qw( getopts );
#use Smart::Comments;
use POSIX ();
use POSIX qw(strftime);

use Term::ANSIColor;

my %opts;
my ($interval, $count); 
my $script = File::Basename::basename($0);
my $version = "0.0.1";
my $STAT = "/proc/stat";
my $INTERRUPTS = "/proc/interrupts";
my $SOFTIRQS = "/proc/softirqs";

use constant M_D_CPU => 0b0001;
use constant M_D_IRQ_SUM  => 0b0010;
use constant M_D_IRQ_CPU  => 0b0100;
use constant M_D_SOFTIRQS => 0b1000;

use constant K_ALL  => "ALL";
use constant F_P_OPTION => 0b0001;
use constant F_P_ON => 0b0010;

use constant K_SUM  => "SUM";
use constant K_CPU  => "CPU";
use constant K_SCPU => "SCPU";
use constant K_ON   => "ON";

use constant NR_IRQCPU_PREALLOC => 3;
#---------------------------begin---------------------
$|++;

getopts("hAI:uP:V", \%opts)
    or die print &usage();
### %opts

my $nr = &get_cpu_nr();
### $nr
my $actflags = 0;
my $actset = 0;
my $flags = 0;
($actflags, $flags) = &deal_opt(\%opts, $nr);
### $actflags

if(@ARGV >= 3) {
    print "The problem of command line parameters too much!\n";
    print &usage();
    exit;
} elsif (@ARGV > 0) {
    ($interval, $count) = @ARGV;
}

my (@st_cpu, @st_irq);
my (@st_irqcpu, @st_softirqcpu);
my ($hz, $irqcpu_nr, $softirqcpu_nr);
my (@uptime, @uptime0);

my ($row, $col) = &get_winsize();
### $row
### $col
#------main-------
&main();
#print "\n";
#----------------------end----------------------------

sub main {
    $hz = POSIX::sysconf( &POSIX::_SC_CLK_TCK ) || 100;
### $hz
    $irqcpu_nr = &get_irqcpu_nr($INTERRUPTS, NR_IRQCPU_PREALLOC);
### $irqcpu_nr
    $softirqcpu_nr = &get_irqcpu_nr($SOFTIRQS, NR_IRQCPU_PREALLOC);
### $softirqcpu_nr
    
    # print the infomation header.
    &print_gal_header($nr);
    #printf("\n%-11s  CPU  %%usr %%nice  %%sys %%iowait  %%irq  %%soft %%steal %%guest %%gnice %%idle\n", $tm);
    printf("\n%-11s  CPU    %%usr   %%nice    %%sys %%iowait    %%irq   %%soft  %%steal  %%guest  %%gnice   %%idle\n", &current_time());
    
    &rw_mpstat_loop($interval, $count); 
}

sub rw_mpstat_loop {
    my $interval = shift;
    my $count = shift;
    my $running = 0;
    my $tm_string = &current_time();
    #print "$now $h\n"; 

    if($nr > 1) {
        $uptime0[0] = 0;
        $uptime0[0] = &read_uptime($hz);
        ### $uptime0
    }
    @st_cpu = &read_stat_cpu($nr);
    ### @st_cpu
    if (! $uptime0[0] and scalar @st_cpu > 1) {
        $uptime0[0] = $st_cpu[1]->{"user"} + $st_cpu[1]->{"nice"} +
            $st_cpu[1]->{"sys"} + $st_cpu[1]->{"idle"} +
            $st_cpu[1]->{"iowait"} + $st_cpu[1]->{"hardirq"} +
            $st_cpu[1]->{"softirq"} + $st_cpu[1]->{"steal"};
    }
    ### $uptime0[0]
    $uptime[0] = $st_cpu[0]->{"user"} + $st_cpu[0]->{"nice"} +
            $st_cpu[0]->{"sys"} + $st_cpu[0]->{"idle"} +
            $st_cpu[0]->{"iowait"} + $st_cpu[0]->{"hardirq"} +
            $st_cpu[0]->{"softirq"} + $st_cpu[0]->{"steal"};
    
    if(&get_bit($actflags, M_D_IRQ_SUM)) {
        @st_irq = &read_stat_irq($nr);
        ### @st_irq
    }

    if(&get_bit($actflags, M_D_IRQ_SUM) || 
        &get_bit($actflags, M_D_IRQ_CPU)) {
        @st_irqcpu = &read_interrupts_stat($INTERRUPTS);
    }

    if(&get_bit($actflags, M_D_SOFTIRQS)) {
        @st_softirqcpu = &read_interrupts_stat($SOFTIRQS); 
    }

    if($interval and $interval > 0) {
        $running = -1;
    } else {
        &write_stats($tm_string);
        exit;
    }

    do {
        if($interval and $interval > 0) {
            select(undef, undef, undef, $interval);
            $tm_string = &current_time();
            $#st_cpu = -1;
            @st_cpu = &read_stat_cpu($nr);
            &write_stats($tm_string);
        }

        if($count and $count > 0) { 
            $count--;
            if ($count <= 0) {
                exit;
            }
        }
    } while ($running);
}

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

sub get_irqcpu_nr {
    my ($file, $pre) = @_;
    my $irq_nr = 0;

    if (! $file) {
        return $irq_nr;
    }

    $pre = 3 unless $pre;

    open(my $fd, "<", $file);

    if (!$fd) {
        return 0;
    }

    while(<$fd>) {
        if($_ =~ ":") {
            $irq_nr++;
        }
    }

    close($fd);

    return $irq_nr + $pre; 
}

sub read_uptime {
    my $HZ = shift;
    ### $HZ
    my $UPTIME = "/proc/uptime";

    open(my $fd, "<", $UPTIME);
    return 0 unless $fd;

    my ($second, $cent) = split(" ", <$fd>);
    ### $second
    ### $cent
    close($fd);

    return ($second * $HZ + $cent * $HZ / 100); 
}

sub read_stat_cpu {
    my $nr = shift;
    my $cpustat = "/proc/stat";
    my @arrays;

    if(!-e $cpustat) {
        print("The file of /proc/stat is not found!\n");
        exit;
    }

    open(my $fd, "<", $cpustat);
    if(!$fd) {
        print("The file of /proc/stat is not found!\n");
        exit;
    }

    my $st_cpu = 
     {   
        "user" => 0,
        "nice" => 0,
        "sys" => 0,
        "idle" => 0,
        "iowait" => 0,
        "hardirq" => 0,
        "softirq" => 0,
        "steal" => 0,
        "guest" => 0,
        "guest_nice" => 0
    };
    while(<$fd>) {
        if($_ =~ /cpu /) {
            # print $_;
            (undef, $st_cpu->{"user"}, $st_cpu->{"nice"}, $st_cpu->{"sys"},
             $st_cpu->{"idle"}, $st_cpu->{"iowait"}, $st_cpu->{"hardirq"},
             $st_cpu->{"softirq"}, $st_cpu->{"steal"}, $st_cpu->{"guest"},
             $st_cpu->{"guest_nice"}) = split(/\s+/, $_);
            ### $st_cpu
            push(@arrays, $st_cpu);
        } elsif ($_ =~ /cpu\d/) {
            # print $_;
            (undef, $st_cpu->{"user"}, $st_cpu->{"nice"}, $st_cpu->{"sys"},
             $st_cpu->{"idle"}, $st_cpu->{"iowait"}, $st_cpu->{"hardirq"},
             $st_cpu->{"softirq"}, $st_cpu->{"steal"}, $st_cpu->{"guest"},
             $st_cpu->{"guest_nice"}) = split(/\s+/, $_);
            ### $st_cpu
            push(@arrays, $st_cpu);
        } else {
            last;
        }
    }
    
    close($fd);
    return @arrays;
}

sub read_stat_irq {
    my $nr = shift;
    my $STAT = "/proc/stat";
    my @array;
    my @st_irq;

    open(my $fd, "<", $STAT);
    return undef unless $fd;

    while(<$fd>) {
        if ($_ =~ "intr") {
            (undef, @array) = split(" ", $_);
            last;
        }
    }

    if($nr and $nr > 1) {
        while($nr > 1) {
            push(@st_irq, shift(@array));
        }
    } else {
        push(@st_irq, shift(@array));
    }

    return @st_irq;
}

sub read_interrupts_stat {
    my $file = shift;

    return undef;
}

sub write_stats {
    my $tm = shift;

    printf("%-11s  all", &current_time());
    printf("  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f\n",
            (($st_cpu[0]->{user} - $st_cpu[0]->{guest}) / $uptime[0] * 100),
            (($st_cpu[0]->{nice} - $st_cpu[0]->{guest_nice}) / $uptime[0] * 100),
            ($st_cpu[0]->{sys} / $uptime[0] * 100),
            ($st_cpu[0]->{iowait} / $uptime[0] * 100),
            ($st_cpu[0]->{hardirq} / $uptime[0] * 100),
            ($st_cpu[0]->{softirq} / $uptime[0] * 100),
            ($st_cpu[0]->{steal} / $uptime[0] * 100),
            ($st_cpu[0]->{guest} / $uptime[0] * 100),
            ($st_cpu[0]->{guest_nice} / $uptime[0] * 100),
            ($st_cpu[0]->{idle} / $uptime[0] * 100));
}

# get and format the date string.
sub current_time {
    my $now = strftime "%H:%M:%S", localtime();
    my ($h, undef, undef) = split(":", $now);
        
    $h = $h < 12 ? "AM" : "PM";

    return $now . " $h"; 
}

sub get_bit {
    my ($actflag, $mode) = @_;

    return ($actflag & $mode);
}

# deal with the options from the command line.
sub deal_opt {
    my $opts = shift;
    my $nr = shift;
    my $acts = 0;
    my $flags = 0;
    my $cpu_bitmap = 0;
    ### $opts

    while (my ($k, $v) = each %$opts) {
        ### $k
        ### $v
        if($k =~ /^I$/) {
            $actset = 1;
            if($v == K_SUM) {
                $acts |= M_D_IRQ_SUM;
            } elsif ($v == K_CPU) {
                $acts |= M_D_IRQ_CPU;
            } elsif ($v == K_SCPU) {
                $acts |= M_D_SOFTIRQS;
            } elsif ($v == K_ALL) {
                $acts |= M_D_IRQ_SUM + M_D_IRQ_CPU + M_D_SOFTIRQS;
            } else {
                print &usage();
                exit;
            }
        } elsif ($k =~ /^P$/) {
            $flags |= F_P_OPTION;
            my @array = split(",", $v);
            foreach my $e (@array) {
                if ($e == K_ALL or $e == K_ON) {
                    # display all cpu infomation.
                    $cpu_bitmap |= 2 ** $nr - 1;
                    if($e == K_ON) {
                        $flags |= F_P_ON;
                    }
                } elsif ($e =~ /^\d+$/) {
                    if($e >= $nr) {
                        print "The P option of cpu number is too large.\n";
                        print &usage();
                        exit;
                    } else {
                        # TODO: add cpu_bitmap operator 
                        # Select all processors
                        # memset(cpu_bitmap, 0xff, ((cpu_nr + 1) >> 3) + 1);
                    } 
                } else {
                    print &usage();
                    exit;
                }
            }
        } elsif ($k =~ /^A$/) {
            $actset = 1;
            $acts |= M_D_CPU + M_D_IRQ_SUM + M_D_IRQ_CPU + M_D_SOFTIRQS; 
            $flags |= F_P_OPTION;
            # TODO: add cpu_bitmap operator 
            # Select all processors
            # memset(cpu_bitmap, 0xff, ((cpu_nr + 1) >> 3) + 1);
        } elsif ($k =~ /^u$/) {
            $acts |= M_D_CPU;
        } elsif ($k =~ /^h/) {
            print &usage();
            exit;
        } elsif ($k =~ /^V/) {
            &version($script, $version);
            exit;
        } else {
            print &usage();
            exit;
        }
    }

    if (!$actset) {
        $acts |= M_D_CPU;
    }

    if (!&get_bit($flags, F_P_OPTION)) {
        $cpu_bitmap = 1;
    }

    return ($acts, $flags, $cpu_bitmap);
}

# get the size of the terminal.
sub get_winsize {
    require 'sys/ioctl.ph';
    CORE::warn "no TIOCGWINSZ \n" unless defined &TIOCGWINSZ;
    open(my $tty_fh, "+</dev/tty") or CORE::warn "No tty: $!\n";
    my $winsize;
    unless (ioctl($tty_fh, &TIOCGWINSZ, $winsize='')) {
        CORE::warn sprintf "$script: ioctl TIOCGWINSZ (%08x: $!)\n", &TIOCGWINSZ;
    }
    close($tty_fh);

    #my ($col, $row, $xpixel, $ypixel) = unpack('S4', $winsize);
    my ($row, $col) = unpack('S4', $winsize);

    return ($row, $col);
}

# print infomation header
sub print_gal_header {
    my $nr = shift;
    my $time = `date +"%m/%d/%Y"`;
    chomp($time);
    ### $time
    my @sysinfo = split(" ", `uname -a`);
    ### @sysinfo
    print "$sysinfo[0] $sysinfo[2] ($sysinfo[1])\t$time\t_$sysinfo[11]_ ($nr CPU)\n";
}
