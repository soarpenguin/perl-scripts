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
use Getopt::Long;
use POSIX ();
use POSIX qw(strftime);

use Term::ANSIColor;
my $DEBUG = 0;
if ($DEBUG) {
    eval q{
        use Smart::Comments;
    };
    die $@ if $@;
}

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

#getopts("hAI:uP:V", \%opts)
#    or die print &usage();
GetOptions('help|h' => \$opts{h},
        'ALL|A'     => \$opts{A},
        'I=s'       => \$opts{I},
        'u'         => \$opts{u},
        'P|p=s'     => \$opts{P},
        'version|V' => \$opts{V})
    or die print &usage();
### %opts

my $nr = &get_cpu_nr();
### $nr
my $actflags = 0;
my $actset = 0;
my $flags = 0;
my $cpu_bitmap = 0;
($actflags, $flags, $cpu_bitmap) = &deal_opt(\%opts, $nr);
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
my (@uptime, @uptime0, @mp_tstamp);
my $curr = 1;

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
    
    $mp_tstamp[0] = localtime();
    # print the infomation header.
    &print_gal_header($nr);
    #printf("\n%-11s  CPU  %%usr %%nice  %%sys %%iowait  %%irq  %%soft %%steal %%guest %%gnice %%idle\n", $tm);
    printf("\n%-11s  CPU    %%usr   %%nice    %%sys %%iowait    %%irq   %%soft  %%steal  %%guest  %%gnice   %%idle\n", &fmt_time($mp_tstamp[0]));
    
    &rw_mpstat_loop($interval, $count); 
}

sub rw_mpstat_loop {
    my $interval = shift;
    my $count = shift;
    my $running = 0;

    if($nr > 1) {
        $uptime0[0] = 0;
        $uptime0[0] = &read_uptime($hz);
        ### @uptime0
    }
    $st_cpu[0] = &read_stat_cpu($nr);
    ### @st_cpu
    #@st_cpu = &read_stat_cpu($nr);
    ### @st_cpu
    #if (! $uptime0[0] and scalar @st_cpu > 1) {
    #    $uptime0[0] = $st_cpu[1]->{"user"} + $st_cpu[1]->{"nice"} +
    #        $st_cpu[1]->{"sys"} + $st_cpu[1]->{"idle"} +
    #        $st_cpu[1]->{"iowait"} + $st_cpu[1]->{"hardirq"} +
    #        $st_cpu[1]->{"softirq"} + $st_cpu[1]->{"steal"};
    #}
    if (! $uptime0[0] and scalar $st_cpu[0] > 1) {
        $uptime0[0] = $st_cpu[0][1]->{"user"} + $st_cpu[0][1]->{"nice"} +
            $st_cpu[0][1]->{"sys"} + $st_cpu[0][1]->{"idle"} +
            $st_cpu[0][1]->{"iowait"} + $st_cpu[0][1]->{"hardirq"} +
            $st_cpu[0][1]->{"softirq"} + $st_cpu[0][1]->{"steal"};
    }
    ### @uptime0
    #$uptime[0] = $st_cpu[0]->{"user"} + $st_cpu[0]->{"nice"} +
    #        $st_cpu[0]->{"sys"} + $st_cpu[0]->{"idle"} +
    #        $st_cpu[0]->{"iowait"} + $st_cpu[0]->{"hardirq"} +
    #        $st_cpu[0]->{"softirq"} + $st_cpu[0]->{"steal"};
    $uptime[0] = $st_cpu[0][0]->{"user"} + $st_cpu[0][0]->{"nice"} +
            $st_cpu[0][0]->{"sys"} + $st_cpu[0][0]->{"idle"} +
            $st_cpu[0][0]->{"iowait"} + $st_cpu[0][0]->{"hardirq"} +
            $st_cpu[0][0]->{"softirq"} + $st_cpu[0][0]->{"steal"};
    ### @uptime
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
        $mp_tstamp[2] = $mp_tstamp[0];
        ### @mp_tstamp
        $uptime[2] = $uptime[0];
        ### @uptime
        $uptime0[2] = $uptime0[0];
        ### @uptime0
        $st_cpu[2] = $st_cpu[0];
        ### @st_cpu
        $st_irq[2] = $st_irq[0];
        ### @st_irq
        $st_irqcpu[2] = $st_irqcpu[0];
        ### @st_irqcpu
        if(&get_bit($actflags, M_D_SOFTIRQS)) {
            $st_softirqcpu[2] = $st_softirqcpu[0];
        }
    } else {
        $mp_tstamp[1] = $mp_tstamp[0];
        # print "$mp_tstamp[0]\t $mp_tstamp[1]\n";
        &write_stats($mp_tstamp[0]);
        exit;
    }

    do {
        select(undef, undef, undef, $interval);
        # $tm_string = &fmt_time();
        $st_cpu[$curr] = undef;
        $mp_tstamp[$curr] = localtime();
        if($nr > 1) {
            $uptime0[$curr] = 0;
            $uptime0[$curr] = &read_uptime($hz);
        }

        $st_cpu[$curr] = &read_stat_cpu($nr);
        
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

        &write_stats($mp_tstamp[0]);

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
    return \@arrays;
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

    return \@st_irq;
}

sub read_interrupts_stat {
    my $file = shift;

    return undef;
}

sub write_stats {
    my $tm = shift;

    printf("%-11s  all", &fmt_time($tm));
    printf("  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f\n",
            (($st_cpu[0][0]->{user} - $st_cpu[0][0]->{guest}) / $uptime[0] * 100),
            (($st_cpu[0][0]->{nice} - $st_cpu[0][0]->{guest_nice}) / $uptime[0] * 100),
            ($st_cpu[0][0]->{sys} / $uptime[0] * 100),
            ($st_cpu[0][0]->{iowait} / $uptime[0] * 100),
            ($st_cpu[0][0]->{hardirq} / $uptime[0] * 100),
            ($st_cpu[0][0]->{softirq} / $uptime[0] * 100),
            ($st_cpu[0][0]->{steal} / $uptime[0] * 100),
            ($st_cpu[0][0]->{guest} / $uptime[0] * 100),
            ($st_cpu[0][0]->{guest_nice} / $uptime[0] * 100),
            ($st_cpu[0][0]->{idle} / $uptime[0] * 100));
}

sub write_stats_core {
    my $g_itv = &get_interval(1, !$curr, $curr);
    my $itv = $g_itv;

    if($nr > 1) {
        $itv = &get_interval(0, !$curr, $curr);
    }

    # Print CPU stats
    if(&get_bit($actflags, M_D_CPU)) {
        if($cpu_bitmap & 1) {
            printf("%-11s  all", &fmt_time($mp_tstamp[$curr]));

            printf("  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f\n",
                ($st_cpu[$curr][0]->{user} - $st_cpu[$curr][0]->{guest}) <
                ($st_cpu[!$curr][0]->{user} - $st_cpu[!$curr][0]->{guest}) ?
                 0.0 :
                &ll_sp_value(($st_cpu[!$curr][0]->{user} - $st_cpu[!$curr][0]->{guest}),
                    ($st_cpu[$curr][0]->{user} - $st_cpu[$curr][0]->{guest}), 
                    $g_itv),

                ($st_cpu[$curr][0]->{nice} - $st_cpu[$curr][0]->{guest_nice}) <
                ($st_cpu[!$curr][0]->{nice} - $st_cpu[!$curr][0]->{guest_nice}) ?
                 0.0 :
                &ll_sp_value(($st_cpu[!$curr][0]->{nice} - $st_cpu[!$curr][0]->{guest_nice}),
                    ($st_cpu[$curr][0]->{nice} - $st_cpu[$curr][0]->{guest_nice}),
                    $g_itv),
                &ll_sp_value($st_cpu[$curr][0]->{sys},
                    $st_cpu[!$curr][0]->{sys},
                    $g_itv),
                &ll_sp_value($st_cpu[$curr][0]->{iowait},
                    $st_cpu[!$curr][0]->{iowait},
                    $g_itv),
                &ll_sp_value($st_cpu[$curr][0]->{hardirq},
                    $st_cpu[!$curr][0]->{hardirq},
                    $g_itv),
                &ll_sp_value($st_cpu[$curr][0]->{softirq},
                    $st_cpu[!$curr][0]->{softirq},
                    $g_itv),
                &ll_sp_value($st_cpu[$curr][0]->{steal},
                    $st_cpu[!$curr][0]->{steal},
                    $g_itv),
                &ll_sp_value($st_cpu[$curr][0]->{guest},
                    $st_cpu[!$curr][0]->{guest},
                    $g_itv),
                &ll_sp_value($st_cpu[$curr][0]->{guest_nice},
                    $st_cpu[!$curr][0]->{guest_nice},
                    $g_itv),
                ($st_cpu[$curr][0]->{idle} < $st_cpu[!$curr][0]->{idle}) ?
                 0.0 :
                &ll_sp_value($st_cpu[$curr][0]->{idle},
                    $st_cpu[!$curr][0]->{idle},
                    $g_itv));
        }

        for(my $i = 1; $i <= $nr; $i++) {
			
            # TODO: Check if we want stats about this proc */
			#if (!(*(cpu_bitmap + (cpu >> 3)) & (1 << (cpu & 0x07))))
            #	continue;

            if(($st_cpu[$curr][$i]->{user} + $st_cpu[$curr][$i]->{nice} +
                $st_cpu[$curr][$i]->{sys} + $st_cpu[$curr][$i]->{iowait} +
                $st_cpu[$curr][$i]->{idle} + $st_cpu[$curr][$i]->{steal} +
                $st_cpu[$curr][$i]->{hardirq} + $st_cpu[$curr][$i]->{softirq}) == 0) {
                
                if(!&get_bit($flags, F_P_ON)) {
					printf("%-11s %4d  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f  %6.2f\n",
					       &fmt_time($mp_tstamp[$curr]), $i - 1,
					       0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
                }
                next;
            }

			printf("%-11s %4d", &fmt_time($mp_tstamp[$curr]), $i - 1);
        }
    }
    
    # TODO: print total number of interrupts per processor
    if(&get_bit($actflags, M_D_IRQ_SUM)) {
        # TODO:
    }

    if(&get_bit($actflags, M_D_IRQ_CPU)) {
        # TODO: write_irqcpu_stats(st_irqcpu)
    }

    if(&get_bit($actflags, M_D_SOFTIRQS)) {
        # TODO: write_irqcpu_stats(st_softirqcpu)
    }
    # Fix CPU counter values for every offline CPU
}

# get and format the date string.
sub fmt_time {
    my $tm_string = shift;
    my $now = "00:00:00";
    
    if($tm_string =~ /(\d+:\d+:\d+)/) {
        $now = $1;
    }
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

    while (my ($k, $v) = each %$opts) {
        ### $k
        ### $v
        if($k =~ /^I$/) {
            if($v) {
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
            }
        } elsif ($k =~ /^P$/) {
            if($v) {
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
            }
        } elsif ($k =~ /^A$/) {
            if($v) {
                $actset = 1;
                $acts |= M_D_CPU + M_D_IRQ_SUM + M_D_IRQ_CPU + M_D_SOFTIRQS; 
                $flags |= F_P_OPTION;
                # TODO: add cpu_bitmap operator 
                # Select all processors
                # memset(cpu_bitmap, 0xff, ((cpu_nr + 1) >> 3) + 1);
            }
        } elsif ($k =~ /^u$/) {
            if($v) {
                $acts |= M_D_CPU;
            }
        } elsif ($k =~ /^h/) {
            if($v) {
                print &usage();
                exit;
            }
        } elsif ($k =~ /^V/) {
            if($v) {
                &version($script, $version);
                exit;
            }
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

sub get_interval {
    my ($bool, $prev, $curr) = @_;
    my $itv;

    if($bool) {
        $itv = $uptime[$curr] - $uptime[$prev];
        if($itv) {
            return $itv;
        } else {
            return 1;
        }
    } else {
        $itv = $uptime0[$curr] - $uptime0[$prev];
        if($itv) {
            return $itv;
        } else {
            return 1;
        }
    }
}

sub ll_sp_value {
    my ($value1, $value2, $itv) = @_;

    return ($value2 - $value1) / $itv * 100;
}
