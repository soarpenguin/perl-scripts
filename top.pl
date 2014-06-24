#!/usr/bin/perl
#

# top.pl -- top command implemented use perl. {{{1
#   get infomation from /proc system.
#   the main file for system info is:
#    /proc/stat /proc/<pid>/status /proc/<pid>/statm etc.
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Nov.27 2012
# 1}}}

#use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use POSIX qw(strftime);
use File::Spec;

use Term::ANSIColor;
#print color("red"), "Stop!\n", color("reset");
#print color("green"), "Go!\n", color("reset");

my $DEBUG = 0;
if ($DEBUG) {
    eval q{
        use Smart::Comments;
    };
    die $@ if $@;
}

my ($delay, $user);
my $numbers = -1;
my ($sleeping, $running, $zombie, $stoped);
my $proc = '/proc';
my $myversion = '0.1.0';
my $script = &_my_program();
my $pagesize = &getpagesize();
my $Hertz = &hertz_hack();
my $header_row = 8;

my $usage = "
Usage: $script [option]...

       -d : Delay time interval as:  -d ss.tt (seconds.tenths)
            Specifies the delay between screen updates, and overrides the
            corresponding  value  in one's personal configuration file or
            the startup default.  Later this can be changed with the  'd'
            or 's' interactive commands.

            Fractional  seconds are honored, but a negative number is not
            allowed.  In all cases, however, such changes are  prohibited
            if  top  is running in 'Secure mode', except for root (unless
            the 's' command-line option was used).  For additional infor‐
            mation  on  'Secure  mode' see topic 5a. SYSTEM Configuration
            File.

       -h, --help 
            Display this help and exit

       -n : Number of iterations limit as:  -n number
            Specifies  the  maximum  number of iterations, or frames, top
            should produce before ending.

       -u : Monitor by user as:  -u somebody
            Monitor only processes with an effective  UID  or  user  name
            matching that given.

       -V   Display version information.
";

my $ret = GetOptions( 
    'delay|d=f' => \$delay,   
    'number|n=i'=> \$numbers,
    'user|u=s'  => \$user,
    'help|h'	=> \&usage,
    'version|V' => \&version
);

$| = 1;

if(! $ret) {
    &usage();
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# detect the /proc mounted. the system info from it.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
if(! -e $proc) {
    &mydie("The /proc filesyestem is not mounted, try \$mount /proc.");
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# set the delay time of every display.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
if(!$delay) {
    $delay = 3;
} elsif($delay < 0) {
    $delay = -$delay;
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# detect the size of terminal, set the row number of display item.
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
my $col = 80;
my $row = 24;

require 'sys/ioctl.ph';
CORE::die "no TIOCGWINSZ \n" unless defined &TIOCGWINSZ;
open(my $tty_fh, "+</dev/tty") or CORE::die "No tty: $!\n";
my $winsize;
unless (ioctl($tty_fh, &TIOCGWINSZ, $winsize='')) {
    CORE::die sprintf "$script: ioctl TIOCGWINSZ (%08x: $!)\n", &TIOCGWINSZ;
}
close($tty_fh);

#my ($col, $row, $xpixel, $ypixel) = unpack('S4', $winsize);
($row, $col) = unpack('S4', $winsize);
if($col < 80) {
    print color("red"), "Need >= 80 column screen.\n", color("reset");
    exit;
} else {
    $row -= $header_row;
}

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# function for signal action
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
sub stop {
    my $signame = shift;
    &gotoxy($row + $header_row, 0);
    print color("red"), "Stoped by SIG$signame\n", color("reset");
    &showcursor();
    # &echo();
    exit;
}

sub suspend {
    # TODO: add suspend code.
}

BEGIN {
    $SIG{ALRM} = __PACKAGE__ . "::stop";
    $SIG{ALRM} = \&stop; # best strategy
    $SIG{HUP} = __PACKAGE__ . "::stop";
    $SIG{HUP} = \&stop; # best strategy
    $SIG{INT} = __PACKAGE__ . "::stop";
    $SIG{INT} = \&stop; # best strategy
    $SIG{PIPE} = __PACKAGE__ . "::stop";
    $SIG{PIPE} = \&stop; # best strategy
    $SIG{QUIT} = __PACKAGE__ . "::stop";
    $SIG{QUIT} = \&stop;
    $SIG{TERM} = __PACKAGE__ . "::stop";
    $SIG{TERM} = \&stop; # best strategy
    $SIG{TSTP} = __PACKAGE__ . "::suspend";
    $SIG{TSTP} = \&suspend; # best strategy
    $SIG{TTIN} = __PACKAGE__ . "::suspend";
    $SIG{TTIN} = \&suspend; # best strategy
    $SIG{TTOU} = __PACKAGE__ . "::suspend";
    $SIG{TTOU} = \&suspend; # best strategy
}

#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#               the main function is start                      +
#++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
my @files;
my $dh;
my %savecpu;
my $first = 0;
my $rin = '';

my @cpuinfo = &get_cpu_info();
### @cpuinfo
if(!@cpuinfo) {
    &mydie("Get cpu infomation failed!");
}

my %cpuhash = (
    "u" => $cpuinfo[0]->{"u"},
    "s" => $cpuinfo[0]->{"s"},
    "n" => $cpuinfo[0]->{"n"},
    "i" => $cpuinfo[0]->{"i"},
    "w" => $cpuinfo[0]->{"w"}
);
## %cpuhash

&clrscr();
#&hidecursor();
# &noecho();
do {
    
START:
    ($sleeping, $running, $zombie, $stoped) = (0, 0, 0, 0);
    @files = ();
    if(! opendir $dh, $proc) {
        &mydie("Open the $proc failed!");
    }
    @files = readdir($dh);
    closedir($dh);

    @files = grep { /^(\d)+$/ } @files;
    my $num = @files;
    my ($memtotal,$memfree,$buf,$cache,$swaptotal,$swapfree) = &get_memswap_info();
    my ($memused, $swapused) = ($memtotal - $memfree, $swaptotal - $swapfree);

    #my $clear_screen = `clear`;
    #print $clear_screen;
    &gotoxy(0, 0);

    my $now = strftime "%H:%M:%S", localtime();
    #my ($min, $hour, $day, $fd);
    my $uptime;
    my $fd;

    $uptime = &fmttime(&get_uptime()); 
    my ($sysload1, $sysload5, $sysload15);
    #open($fd, "<", File::Spec->catfile($proc, "loadavg"));
    open($fd, "<", "$proc/loadavg");
    if(!$fd) {
        ($sysload1, $sysload5, $sysload15) = (0, 0, 0);
    } else {
        ($sysload1, $sysload5, $sysload15) = split(/\s+/, <$fd>);
        close($fd);
    }

    my $count = 0;
    my @process;
    $#process=-1;
    my $cputotal = 0;
    
    foreach my $file (@files) {
        my $proc_t = 
            {   "pid" => "0", # process id 
                "ppid" => "0", # pid of parent process */
                
                "pcpu" => "0", # %CPU usage (is not filled in by readproc!!!) */
                "state" => "", # single-char code for process state (S=sleeping) */
                "utime" => "0", # user-mode CPU time accumulated by process */
                "stime" => "0", # kernel-mode CPU time accumulated by process */
                # and so on...
                "cutime" => "0", # cumulative utime of process and reaped children */
                "cstime" => "0", # cumulative stime of process and reaped children */
                "start_time" => "0", # start time of process -- seconds since 1-1-70 */
                "tics" => "0", # XXX for store the utime+stime
                ## ifdef SIGNAL_STRING
                # char
                # Linux 2.1.7x and up have 64 signals. Allow 64, plus '\0' and padding. */
                "signal" => "0", #[18]  mask of pending signals */
                "blocked" => "0", #[18]  mask of blocked signals */
                "sigignore" => "0", #[18]  mask of ignored signals */
                "sigcatch" => "0", #[18]  mask of caught signals */
                ##else
                # long long
                # Linux 2.1.7x and up have 64 signals. */
                # signal, # mask of pending signals */
                # blocked, # mask of blocked signals */
                # sigignore, # mask of ignored signals */
                # sigcatch; # mask of caught signals */
                ##endif
                #long
                "priority" => "0", # kernel scheduling priority */
                "timeout" => "0", # ? */
                "nice" => "0", # standard unix nice level of process */
                "rss" => "0", # resident set size from /proc/#/stat (pages) */
                "it_real_value" => "0", # ? */
                # the next 7 members come from /proc/#/statm */
                "size" => "0", # total # of pages of memory */
                "resident" => "0", # number of resident set (non-swapped) pages (4k) */
                "share" => "0", # number of pages of shared (mmap'd) memory */
                "trs" => "0", # text resident set size */
                "lrs" => "0", # shared-lib resident set size */
                "drs" => "0", # data resident set size */
                "dt" => "0", # dirty pages */
                #unsigned long
                "vm_size" => 0, # same as vsize in kb */
                "vm_lock" => "0", # locked pages in kb */
                "vm_rss" => 0, # same as rss in kb */
                "vm_data" => 0, # data size */
                "vm_stack" => 0, # stack size */
                "vm_exe" => 0, # executable size */
                "vm_lib" => 0, # library size (all pages, not just used ones) */
                "rtprio" => "0", # real-time priority */
                "sched" => "0", # scheduling class */
                "vsize" => 0, # number of pages of virtual memory ... */
                "rss_rlim" => "0", # resident set size limit? */
                "flags" => "0", # kernel flags for the process */
                "min_flt" => "0", # number of minor page faults since process start */
                "maj_flt" => "0", # number of major page faults since process start */
                "cmin_flt" => "0", # cumulative min_flt of process and child processes */
                "cmaj_flt" => "0", # cumulative maj_flt of process and child processes */
                "nswap" => "0", # ? */
                "cnswap" => "0", # cumulative nswap ? */
                "start_code" => "0", # address of beginning of code segment */
                "end_code" => "0", # address of end of code segment */
                "start_stack" => "0", # address of the bottom of stack for the process */
                "kstk_esp" => "0", # kernel stack pointer */
                "kstk_eip" => "0", # kernel instruction pointer */
                "wchan" => "0", # address of kernel wait channel proc is sleeping in */
                #char
                "environ" => "", # environment string vector (/proc/#/environ) */
                "cmdline" => "", # command line string vector (/proc/#/cmdline) */
                #char
                # Be compatible: Digital allows 16 and NT allows 14 ??? */
                "ruser" => "", # [16], # real user name */
                "euser" => "", # [16], # effective user name */
                "suser" => "", # [16], # saved user name */
                "fuser" => "", # [16], # filesystem user name */
                "rgroup" => "", # [16], # real group name */
                "egroup" => "", # [16], # effective group name */
                "sgroup" => "", # [16], # saved group name */
                "fgroup" => "", # [16], # filesystem group name */
                "cmd" => "", # [16]; # basename of executable file in call to exec(2) */
                #int
                "ruid" => "0", 
                "rgid" => "0", # real */
                "euid" => "0", 
                "egid" => "0", # effective */
                "suid" => "0", 
                "sgid" => "0", # saved */
                "fuid" => "0", 
                "fgid" => "0", # fs (used for file access only) */
                "pgrp" => "0", # process group id */
                "session" => "0", # session id */
                "tty" => "0", # full device number of controlling terminal */
                "tpgid" => "0", # terminal process group id */
                "exit_signal" => "0", # might not be SIGCHLD */
                "processor" => "0", # current (or most recent?) CPU */
                ##ifdef FLASK_LINUX
                "sid" => "0"
                ##endif
            };
        #$proc_t -> {"pid"} = $file;
        #$file = File::Spec->catfile($proc, $file);
        $file = "$proc/$file";

        if(! -e $file) {
            next;
        } else {
            #----------/proc/#/stat
            my $fd;
            #open($fd, "<", File::Spec->catfile($file, "stat"));
            open($fd, "<", "$file/stat");
            next unless $fd;
            my $line = <$fd>;
            close $fd;
            
            ( $proc_t->{"pid"}, $proc_t->{"cmd"}, $proc_t->{"state"}, $proc_t->{"ppid"},
              $proc_t->{"pgrp"}, $proc_t->{"session"}, $proc_t->{"tty"}, 
              $proc_t->{"tpgid"}, $proc_t->{"flags"}, $proc_t->{"min_flt"}, 
              $proc_t->{"cmin_flt"}, $proc_t->{"maj_flt"},
              $proc_t->{"cmaj_flt"}, $proc_t->{"utime"}, $proc_t->{"stime"}, $proc_t->{"cutime"},
              $proc_t->{"cstime"}, $proc_t->{"priority"}, $proc_t->{"nice"},
              $proc_t->{"timeout"}, # not sure the value what's mean 
              $proc_t->{"it_real_value"}, $proc_t->{"start_time"}, $proc_t->{"vsize"},
              $proc_t->{"rss"}, $proc_t->{"rss_rlim"}, $proc_t->{"start_code"},
              $proc_t->{"end_code"}, $proc_t->{"start_stack"}, $proc_t->{"kstk_esp"},
              $proc_t->{"kstk_eip"}, $proc_t->{"signal"}, $proc_t->{"blocked"}, 
              $proc_t->{"sigignore"}, $proc_t->{"sigcatch"},  
              $proc_t->{"wchan"}, $proc_t->{"nswap"}, $proc_t->{"cnswap"},
              $proc_t->{"exit_signal"}, $proc_t->{"processor"}, $proc_t->{"rtprio"}, 
              $proc_t->{"sched"}, undef, undef, undef) = split(/\s/, $line);
            #print $proc_t->{"ppid"};
            $proc_t->{"cmd"} =~ s/[()]//g;
            if($proc_t->{"tty"} == 0) {
                $proc_t->{"tty"} = -1;
            }

            if($proc_t->{"priority"} < 0) {
                $proc_t->{"priority"} = 'RT';
            }

            if($first == 0) {
                $proc_t->{"pcpu"} = $proc_t->{"utime"} + $proc_t->{"stime"};
                $proc_t->{"tics"} = $proc_t->{"utime"} + $proc_t->{"stime"};
                $savecpu{"$proc_t->{'pid'}"} = $proc_t->{'tics'};
            } else {
                if(exists $savecpu{"$proc_t->{'pid'}"}) {
                    $proc_t->{"pcpu"} = $proc_t->{"utime"} + $proc_t->{"stime"} 
                                - $savecpu{"$proc_t->{'pid'}"};
                } else {
                    $proc_t->{"pcpu"} = $proc_t->{"utime"} + $proc_t->{"stime"};
                }
                $proc_t->{"tics"} = $proc_t->{"utime"} + $proc_t->{"stime"};
                $savecpu{"$proc_t->{'pid'}"} = $proc_t->{'tics'};
            }

            if($proc_t->{"state"} eq 'S' or $proc_t->{"state"} eq 'D') {
                $sleeping++;
            } elsif($proc_t->{"state"} eq 'T') {
                $stoped++;
            } elsif($proc_t->{"state"} eq 'Z') {
                $zombie++;
            } elsif($proc_t->{"state"} eq 'R') {
                $running++;
            }
            #----------/proc/#/status
            #open($fd, "<", File::Spec->catfile($file, "status"));
            open($fd, "<", "$file/status");
                
            next unless $fd;
            my @lines = <$fd>;
            close $fd;
            foreach my $l (@lines) {
                if($l =~ /Uid:/i) {
                    ( undef, $proc_t->{"ruid"}, $proc_t->{"euid"},
                     $proc_t->{"suid"}, $proc_t->{"fuid"} ) = split(/\s+/, $l); 
                } elsif ($l =~ /Gid:/i) {
                    ( undef, $proc_t->{"rgid"}, $proc_t->{"egid"},
                      $proc_t->{"sgid"}, $proc_t->{"fgid"} ) = split(/\s+/, $l);
                } elsif ($l =~ /VmSize:/i) {
                    ( undef, $proc_t->{"vm_size"}, undef ) = split(/\s+/, $l);
                } elsif ($l =~ /VmLck:/i) {
                    ( undef, $proc_t->{"vm_lock"}, undef ) = split(/\s+/, $l);
                } elsif ($l =~ /VmRss:/i) {
                    ( undef, $proc_t->{"vm_rss"}, undef ) = split(/\s+/, $l);
                } elsif ($l =~ /VmData:/i) {
                    ( undef, $proc_t->{"vm_data"}, undef ) = split(/\s+/, $l);
                } elsif ($l =~ /VmStk:/i) {
                    ( undef, $proc_t->{"vm_stack"}, undef ) = split(/\s+/, $l);
                } elsif ($l =~ /VmExe:/i) {
                    ( undef, $proc_t->{"vm_exe"}, undef ) = split(/\s+/, $l);
                } elsif ($l =~ /VmLib:/i) {
                    ( undef, $proc_t->{"vm_lib"}, undef ) = split(/\s+/, $l);
                }
            }
            #----------/proc/#/statm
            #open($fd, "<", File::Spec->catfile($file, "statm"));
            open($fd, "<", "$file/statm");

            next unless $fd;
            $line = <$fd>;
            close $fd;

            ( $proc_t->{"size"}, $proc_t->{"resident"}, $proc_t->{"share"},
              $proc_t->{"trs"}, $proc_t->{"lrs"}, $proc_t->{"drs"}, 
              $proc_t->{"dt"} ) = split(/\s+/, $line);

            #----------/proc/cmdline
            #open($fd, "<", File::Spec->catfile($file, "cmdline"));
            open($fd, "<", "$file/cmdline");

            next unless $fd;
            $line = <$fd>;
            close $fd;
            $proc_t->{"cmdline"} = $line;
            
            #----------/proc/environ
            #my $result = open($fd, "<", File::Spec->catfile($file, "environ"));
            my $result = open($fd, "<", "$file/environ");
            if($result) {
                next unless $fd;
                $line = <$fd>;
                close $fd;
                $proc_t->{"environ"} = $line;
            } else {
                $proc_t->{"environ"} = " "; 
            }

            $proc_t->{"euser"} = getpwuid($proc_t->{"euid"});
            $proc_t->{"ruser"} = getpwuid($proc_t->{"ruid"});
            $proc_t->{"suser"} = getpwuid($proc_t->{"suid"});
            $proc_t->{"egroup"} = getgrgid($proc_t->{"egid"});
            $proc_t->{"rgroup"} = getgrgid($proc_t->{"rgid"});
            $proc_t->{"fgroup"} = getgrgid($proc_t->{"fgid"});
            ### $proc_t
        }

        if($proc_t->{"state"} eq 'Z') {
            $proc_t->{"cmd"} .= " <defunct>"
        }

        push @process, $proc_t;
    }

    if($first == 0) {
        $first = 1;
        goto START;
    }
    # sort the @process array across multiple columns. (1:pcpu, 2:pid)
    @process =  reverse sort { $a->{"pcpu"} <=> $b->{"pcpu"} || 
            $b->{"pid"} <=> $a->{"pid"} } @process;

#----------------- get infomation of cpu ---------------------------------
    $#cpuinfo=-1;
    @cpuinfo = &get_cpu_info();
    ## @cpuinfo
    my ($u, $n, $s, $i, $w) = (
        $cpuinfo[0]->{"u"} - $cpuhash{"u"},
        $cpuinfo[0]->{"s"} - $cpuhash{"s"},
        $cpuinfo[0]->{"n"} - $cpuhash{"n"},
        $cpuinfo[0]->{"i"} - $cpuhash{"i"},
        $cpuinfo[0]->{"w"} - $cpuhash{"w"}
    );
    %cpuhash = (
        "u" => $cpuinfo[0]->{"u"},
        "s" => $cpuinfo[0]->{"s"},
        "n" => $cpuinfo[0]->{"n"},
        "i" => $cpuinfo[0]->{"i"},
        "w" => $cpuinfo[0]->{"w"}
    );
    if($u < 0) { $u = 0; }
    if($s < 0) { $s = 0; }
    if($n < 0) { $n = 0; }
    if($i < 0) { $i = 0; }
    if($w < 0) { $w = 0; }
    my $total = $u + $s + $n + $i + $w;
    if($total < 1) { $total = 1; }
    my $scale = 100.0 / $total;
    
    # get login user infomation
    my @usernum = &getusers;
    ## @usernum

#----------------- the head infomation of display.------------------------
    &clreol();
    printf("%5s - %8s up %5s, %2d users,  load average: %3s, %3s, %3s\n", 
        $script, $now, $uptime, $#usernum+1, $sysload1, $sysload5, $sysload15);
    ## $uptime
    &clreol();
    printf("Tasks: %3d total,   %2d running, %3d sleeping, %3d stopped, %2d zombie\n",
        $num, $running, $sleeping, $stoped, $zombie);
    &clreol();
printf("Cpu(s):  %2.1f%%us, %2.1f%%sy, %2.1f%%ni, %2.1f%%id, %2.1f%%wa, 0.0%%hi, 0.0%%si, 0.0%%st
Mem:  %8dk total, %8dk used, %8dk free, %8dk buffers
Swap: %8dk total, %8dk used, %8dk free, %8dk cached\n",
        $u*$scale, $s*$scale, $n*$scale, $i*$scale, $w*$scale,
        $memtotal, $memused, $memfree, $buf, 
        $swaptotal, $swapused, $swapfree, $cache);
#------------------------------------------------------------------------
    #
    #print "\n";
    use Term::ANSIColor qw(:pushpop);
    print PUSHCOLOR WHITE ON_BLACK 
        "\n  PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND    \n";
    print POPCOLOR "";
    #print color("reset");

    ## @process
    while($count < $row) {
        #$process[$count]->{"vsize"} = ($process[$count]->{"vsize"})/1024; 
        &clreol();
        printf("%5s %-8s %3s %3s %5s %4s %4s %1s %4.1f %4.1f %9s %-15s\n", 
                $process[$count]->{"pid"}, $process[$count]->{"euser"},
                $process[$count]->{"priority"}, $process[$count]->{"nice"},
                &scale_num($process[$count]->{"size"}, 5, $pagesize), 
                &scale_num($process[$count]->{"resident"}, 4, $pagesize),
                &fmtShare($process[$count]->{"share"}, $pagesize), 
                $process[$count]->{"state"},
                $process[$count]->{"pcpu"} / 3.0, 
                &fmtMemPercent($process[$count]->{"resident"}, $memtotal, $pagesize),
                &scale_tics($process[$count]->{"utime"}+$process[$count]->{"stime"}, 8, $Hertz), 
                $process[$count]->{"cmd"}
            );
        # last;
        $count++;
    }
    #&readyforinterface();
   
    #---------- for -n or --number option-----------
    if($numbers > 0) { $numbers--; } 
    if(! $numbers) { exit; }

    $count = 0;
    vec($rin, fileno(STDIN), 1) = 1;
    if(select($rin, undef, undef, $delay) > 0 &&
       &chin(\$char,1) > 0) {
        &dokey($char);
    }

} while (1);

# &echo();

sub usage {
    print $usage;
    exit;
}

sub version {
    print "$script version $myversion\n";
    exit;
}

sub mywarn {
    return CORE::warn( _my_program(), ': ', @_, "\n" );
}

sub mydie {
    #return CORE::die( _my_program(), ': ', @_, "\n" );
    my ($func, undef, $line) = caller; 
    print (color("red"), _my_program(), " line $line: ");
    print (color("reset"), @_, "\n");
    exit;
}

sub _my_program {
    require File::Basename;
    return File::Basename::basename( $0 );
}

# get swap memory infomation.
sub get_memswap_info {
    my $meminfo = "/proc/meminfo";
    my @memarray;

    if(! -e $meminfo) {
        &mydie("The file of $meminfo not existed!");
    } else {
        my $fd;

        open($fd, "<", $meminfo);
        &mydie("Failed to open the file $meminfo") unless $fd;

        my @lines = <$fd>;
        close $fd;
        #print @lines;
        foreach my $line (@lines) {
            if($line =~ /\bMemTotal:(\s+)(\d+)/) {
                $line =~ s/[^0-9]//g;
                push @memarray, $line;
            } elsif ($line =~ /\bMemFree:(\s+)(\d+)/) {
                $line =~ s/[^0-9]//g;
                push @memarray, $line;
            } elsif ($line =~ /\bBuffers:(\s+)(\d+)/) {
                $line =~ s/[^0-9]//g;
                push @memarray, $line;
            } elsif ($line =~ /\bCached:(\s+)(\d+)/) {
                $line =~ s/[^0-9]//g;
                push @memarray, $line;
            } elsif ($line =~ /\bSwapTotal:(\s+)(\d+)/) {
                $line =~ s/[^0-9]//g;
                push @memarray, $line;
            } elsif ($line =~ /\bSwapFree:(\s+)(\d+)/) {
                $line =~ s/[^0-9]//g;
                push @memarray, $line;
                last;
            }
        }
    }

    return @memarray;
}

# get cpu infomation from /proc/stat.
sub get_cpu_info {
    my $cpustat = "/proc/stat";
    my @arrays;

    if(!-e $cpustat) {
        &mywarn("The file of /proc/stat is not found!");
        return undef;
    }

    open(my $fd, "<", $cpustat);
    if(!$fd) {
        return undef;
    }

    while(<$fd>) {
        if($_ =~ /cpu/) {
                # typedef struct {
                # /* ticks count as represented in /proc/stat */
                # TICS_t u, n, s, i, w;
                # /* tics count in the order of our display */
                # TICS_t u_sav, s_sav, n_sav, i_sav, w_sav;
                # } CPUS_t;
            my $cpu_t = 
             {   
                "u" => 0,
                "s" => 0,
                "n" => 0,
                "i" => 0,
                "w" => 0
            };

            (undef, $cpu_t->{"u"}, $cpu_t->{"s"}, $cpu_t->{"n"},
             $cpu_t->{"i"}, $cpu_t->{"w"}) = split(/\s+/, $_);

            push(@arrays, $cpu_t);
        } else {
            last;
        }
    }
    
    close($fd);
    return @arrays;
}

# get the system pagesize from 
sub getpagesize {
    my $file = '/proc/self/smaps';
    my ($num, $unit);
    my $fd;
    $num = 4096;

    if(! -e $file) {
        Core::warn("The $file is not exist. The pagesize default is 4kB\n");
        return $num;
    } else {
        open($fd, "<", $file);
        while(<$fd>) {
            if($_ =~ /KernelPageSize/i or $_ =~ /MMUPageSize/i) {
                (undef, $num, $unit) = split(/\s+/, $_);
                if($unit =~ /kb/i) {
                    $num <<= 10;
                } elsif ($unit =~ /mb/i) {
                    $num <<= 20;
                } elsif ($unit =~ /gb/i) {
                    $num <<= 30;
                } 
                last;
            }
        }
        close($fd);
        return $num;
    }
}

# get uptime infomation from /proc/uptime
sub get_uptime {
    my $fd;
    my $uptime;
    #open($fd, "<", File::Spec->catfile($proc, "uptime"));
    open($fd, "<",  "$proc/uptime"); 
    if ( !$fd ) {
        $uptime = 0;
    } else {
        ($uptime, undef) = split(/\s+/, <$fd>);
        close($fd);
    }

    return $uptime;
}

# convert seconds to day, hour, minuter.
sub fmttime {
    my $seconds = shift;

    unless($seconds) { return ""; }
    my ($days, $hour, $min);
    my $tmpstring = "";

    $days = int ($seconds / (24 * 60 * 60));
    $hour = ($seconds / (60 * 60) % 24);
    $min = ($seconds / 60 % 60);

    if($days > 1) {
        $tmpstring = "$days days ";
    } elsif ($days > 0) {
        $tmpstring = "$days day ";
    }

    if($hour > 0) {
        $tmpstring .= sprintf("%02d:%02d", $hour, $min);
    } else {
        $tmpstring .= sprintf("%2d min", $min);
    }
}

# format share size.
sub fmtShare {
    my ($share, $pagesize) = @_;

    $share *= ($pagesize >> 10);

    if($share <= 9999) {
        return sprintf("%d", $share);
    } elsif($share <= 1024 * 1024) {
        return sprintf("%dm", $share / 1024);
    } elsif($share <= 1024 * 1024 * 1024) {
        return sprintf("%dg", $share / 1024 / 1024);
    } else {
        return '?';
    }
}

# format 'tics' to fit 'width'
sub scale_tics {
    my ($tics, $width, $Hertz) = @_;
    my ($ss, $ct, $nt);

    $ct = (($tics * 100) / $Hertz) % 100;
    $nt = $tics / $Hertz;
    if($width >= 7) {
        return sprintf("%d:%02d.%02d", int($nt/60), int($nt%60), $ct);
    } elsif($width >= 4) {
        $ss = $nt % 60;
        $nt /= 60;
        return sprintf("%d:%02d", int($nt), $ss);
    } else {
        return '?';
    }
}

# get system HZ value.
sub hertz_hack {
    my ($up_1, $up_2);
    my @tmpcpu;
    my ($Hertz, $jiffies, $h, $cpunum);
    my ($u, $n, $s, $i, $w) = (0, 0, 0, 0, 0);

    do {
        $up_1 = &get_uptime();
        $#tmpcpu=-1;
        @tmpcpu = &get_cpu_info();
        $cpunum = $#tmpcpu;
        ($u, $n, $s, $i, $w) = (
            $tmpcpu[0]->{"u"}, $tmpcpu[0]->{"s"},
            $tmpcpu[0]->{"n"}, $tmpcpu[0]->{"i"},
            $tmpcpu[0]->{"w"} 
        );
        $up_2 = &get_uptime();
    } while(int(($up_2 - $up_1) * 1000.0 / $up_1));

    $jiffies = $u + $n + $s + $i;
    ## $jiffies;
    ## $cpunum
    $h = int($jiffies / (($up_1 + $up_2) / 2) / $cpunum);

    if($h >= 9 and $h <= 11) { $Hertz = 10; } 
    elsif($h >=   18 and $h <=   22) { $Hertz = 20; }
    elsif($h >=   30 and $h <=   34) { $Hertz = 32; }
    elsif($h >=   48 and $h <=   52) { $Hertz = 50; }
    elsif($h >=   58 and $h <=   61) { $Hertz = 60; }
    elsif($h >=   62 and $h <=   65) { $Hertz = 64; }
    elsif($h >=   95 and $h <=  105) { $Hertz = 100; }
    elsif($h >=  124 and $h <=  132) { $Hertz = 128; }
    elsif($h >=  195 and $h <=  204) { $Hertz = 200; }
    elsif($h >=  253 and $h <=  260) { $Hertz = 256; }
    elsif($h >=  393 and $h <=  408) { $Hertz = 400; }
    elsif($h >=  790 and $h <=  808) { $Hertz = 800; }
    elsif($h >=  990 and $h <= 1010) { $Hertz = 1000; }
    elsif($h >= 1015 and $h <= 1035) { $Hertz = 1024; }
    elsif($h >= 1180 and $h <= 1200) { $Hertz = 1200; }
    else { $Hertz = 100; }

    return $Hertz;
}

# format number to fit 'width'
sub scale_num {
    my ($num, $width, $pagesize) = @_;
    $num = $num * $pagesize >> 10;

    if($num <= (10 ** $width - 1)) {
        return sprintf("%d", $num);
    } elsif($num <= 1024 * 1024) {
        return sprintf("%dm", $num / 1024);
    } elsif($num <= 1024 * 1024 * 1024) {
        return sprintf("%dg", $num / 1024 / 1024);
    } else {
        return '?';
    }
}

# convert $proc_t->{"resident"} to memory percentage info.
sub fmtMemPercent {
    my ($tmp, $memtotal, $pagesize) = @_;
    ## $memtotal
    ## $pagesize;
    if(! $tmp or ! $memtotal) {
        return "0";
    }
    $tmp = sprintf("%.1f", ((($tmp * $pagesize) / 1024 * 100) / $memtotal));
    
    return $tmp;
}

# get the number of user login. need User::Utmp. 
# http://search.cpan.org/~mpiotr/User-Utmp-1.8/Utmp.pm
sub getusers {
    #my $result = eval { require User::Utmp; };
    if(eval {require User::Utmp;1;} ne 1) {
        #if(! $result) {
        # if module can't load
        # &mywarn("");
        return (0, 0);
    } else {
        use User::Utmp qw(:constants :utmpx);
        #require User::Utmp; # qw(:constants :utmpx);

        my @utmp = getutx();
        endutxent();
        my @a;
        ## @utmp
        foreach my $utent (@utmp) {
            # if($utent->{'ut_user'})
            if($utent->{'ut_type'} == USER_PROCESS) {
                push @a, $utent->{'ut_user'};  
            }
        }
        return @a;
    }
}

# Esc[2JEsc[1;1H    - Clear screen and move cursor to 1,1 (upper left) pos.
#define clrscr()              puts ("\e[2J\e[1;1H")
sub clrscr {
    print "\e[2J\e[1;1H";
}

# Esc[K     - Erases from the current cursor position to the end of the current line.
#define clreol()              puts ("\e[K")
sub clreol {
    print "\e[K";
}

# Esc[2K            - Erases the entire current line.
#define delline()             puts ("\e[2K")
sub delline {
    print "\e[2K";
}

# Esc[Line;ColumnH    - Moves the cursor to the specified position (coordinates)
#define gotoxy(x,y)           printf("\e[%d;%dH", y, x)
sub gotoxy {
    my ($x, $y) = @_;

    printf("\e[%d;%dH", $x, $y);
}

# Esc[?25l (lower case L)    - Hide Cursor
#define hidecursor()          puts ("\e[?25l")
sub hidecursor {
    print "\e[?25l";
}

# Esc[?25h (lower case H)    - Show Cursor
#define showcursor()          puts ("\e[?25h")
sub showcursor {
    print "\e[?25h";
}
#sub myprint { 
#    print {$fh} @_ 
#}

# for keyboard interface when running a program. 
# read a char by time.
sub readyforinterface {
    if (eval {require Term::ReadKey;1;} ne 1) {
        # if module can't load
    } else {
        Term::ReadKey->import();
        ReadMode('cbreak');

        if (defined (my $char = ReadKey(-1)) ) {
            # input was waiting and it was $char
            &gotoxy(6,0);
            &dokey($char);
        } else {
            # no input was waiting
        }

        ReadMode('normal');
    }
    #if(eval "require Term::ReadKey") {
    #    use Term::ReadKey;
    #}
}

sub dokey {
    my $key = shift;

    if($key eq 'h' or $key eq '?') {
        &clrscr();
        &printhelp();
    }
}

sub chin {
    my $char = shift;
}

sub printhelp {
    print("
Help for Interactive Commands - $script version $myversion
Window 1:Def: Cumulative mode Off.  System: Delay 3.0 secs; Secure mode Off.

  Z,B       Global: 'Z' change color mappings; 'B' disable/enable bold
  l,t,m     Toggle Summaries: 'l' load avg; 't' task/cpu stats; 'm' mem info
  1,I       Toggle SMP view: '1' single/separate states; 'I' Irix/Solaris mode

  f,o     . Fields/Columns: 'f' add or remove; 'o' change display order
  F or O  . Select sort field
  <,>     . Move sort field: '<' next col left; '>' next col right
  R,H     . Toggle: 'R' normal/reverse sort; 'H' show threads
  c,i,S   . Toggle: 'c' cmd name/line; 'i' idle tasks; 'S' cumulative time
  x,y     . Toggle highlights: 'x' sort field; 'y' running tasks
  z,b     . Toggle: 'z' color/mono; 'b' bold/reverse (only if 'x' or 'y')
  u       . Show specific user only
  n or #  . Set maximum tasks displayed

  k,r       Manipulate tasks: 'k' kill; 'r' renice
  d or s    Set update interval
  W         Write configuration file
  q         Quit
          ( commands shown with '.' require a visible task display window ) 
Press 'h' or '?' for help with Windows,
any other key to continue ");

}

sub noecho {
    print `stty -echo`;
}

sub echo {
    print `stty sane`;
}

sub mk_fd_nonblocking {
    use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

    my $fd = shift;
    my $flags = fcntl($fd, F_GETFL, 0)
        or warn "Can't get flags for the fd: $!\n";

    $flags = fcntl($fd, F_SETFL, $flags | O_NONBLOCK)
        or warn "Can't set flags for the fd: $!\n";
}

#-------------------terminal operator-------------------
#my $savedtty;
#use POSIX::1003::Termios;
#
#sub whack_terminal {
#    my $newtty;
#
#    $savedtty = POSIX::1003::Termios->new;
#    $savedtty->getattr(STDIN_FILENO);
#
#    $newtty = POSIX::1003::Termios->new;
#    my $c_lflag = $newtty->getlflag();
#
#    $c_lflag &= ~ICANON;
#    $c_lflag &= ~ECHO;
#
#    $newtty->setlflag($c_lflag);
#    $newtty->tcsetattr(STDIN_FILENO, TCSAFLUSH);
#
#    fflush(stdout);
#}
