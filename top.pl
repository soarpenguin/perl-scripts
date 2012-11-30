#!/usr/bin/perl
#

# top.pl -- ***********. {{{1
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Nov.14 2012
# 1}}}

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use Smart::Comments;
use POSIX qw(strftime);
use File::Spec;

use Term::ANSIColor;
#print color("red"), "Stop!\n", color("reset");
#print color("green"), "Go!\n", color("reset");

my $delay;
my $proc = '/proc';
my $myversion = '0.1.0';
my $script = &_my_program();

my $usage = "
Usage: $script [option]...

       -h, --help 
              Display this help and exit

       -V     Display version information.
";

my $ret = GetOptions( 
	'delay|d=i' => \$delay,   
    'help|h'	=> \&usage,
	'version|V' => \&version
);

$| = 1;

if(! $ret) {
	&usage();
}

if(! -e $proc) {
    &mydie("The /proc filesyestem is not mounted, try \$mount /proc");
}

my @files = ();
my $dh;

if(! opendir $dh, $proc) {
    &mydie("Open the $proc failed");
}

my $col = 80;
my $row = 24;

require 'sys/ioctl.ph';
CORE::die "no TIOCGWINSZ " unless defined &TIOCGWINSZ;
open(my $tty_fh, "+</dev/tty") or CORE::die "No tty: $!";
my $winsize;
unless (ioctl($tty_fh, &TIOCGWINSZ, $winsize='')) {
    CORE::die sprintf "$0: ioctl TIOCGWINSZ (%08x: $!)\n", &TIOCGWINSZ;
}

#my ($col, $row, $xpixel, $ypixel) = unpack('S4', $winsize);
($row, $col) = unpack('S4', $winsize);
#print "(row,col) = ($row,$col)";
if($col < 72) {
    $row /= 2;
} else {
    $row -= 7;
}
#print "(row,col) = ($row,$col)";
close($tty_fh);
#print "\n";

do {
    @files = readdir($dh);
    closedir($dh);

    @files = grep { /^(\d)+$/ } @files;
    my $num = @files;
    my ($memtotal,$memfree,$buf,$cache,$swaptotal,$swapfree) = &get_memswap_info();
    my ($memused, $swapused) = ($memtotal - $memfree, $swaptotal - $swapfree);

    #my $clear_screen = `clear`;
    #print $clear_screen;
    &clrscr();

    my $now = strftime "%H:%M:%S", localtime();
    #my ($min, $hour, $day, $fd);
    my $uptime;
    my $fd;
    open($fd, "<", File::Spec->catfile($proc, "uptime"));
    if ( !$fd ) {
        $uptime = 0;
    } else {
        ($uptime, undef) = split(/\s+/, <$fd>);
        close($fd);
        $uptime = strftime "%H:%M", localtime($uptime)
    }
    # if( !$fd) {
    #     ($min, $hour, $day) = (0, 0, 0);
    # } else {
    #     my ($tmp, undef) = split(/\s+/, <$fd>);
    #     print "$tmp\n";
    #     close($fd);
    #     (undef, $min, $hour, $day)= localtime($tmp);
    #     ### $min
    #     ### $hour
    #     ### $day
    # }
    my ($sysload1, $sysload5, $sysload15);
    open($fd, "<", File::Spec->catfile($proc, "loadavg"));
    if(!$fd) {
        ($sysload1, $sysload5, $sysload15) = (0, 0, 0);
    } else {
        ($sysload1, $sysload5, $sysload15) = split(/\s+/, <$fd>);
        close($fd);
    }
    printf("%5s - %8s up  %3s,  3 users,  load average: %3s, %3s, %3s\n", 
        $script, $now, $uptime, $sysload1, $sysload5, $sysload15);
    ## $uptime
    # if($day > 0) {
    #     printf("%5s - %8s up %3s days, %2s:%2s,  3 users,  load average: %3s, %3s, %3s\n", 
    #         $script, $now, $day, $hour, $min, $sysload1, $sysload5, $sysload15);
    # } else {
    #     printf("%5s - %8s up  %2s:%2s,  3 users,  load average: %3s, %3s, %3s\n", 
    #         $script, $now, $hour, $min, $sysload1, $sysload5, $sysload15);
    # }
#       print("Tasks: $num total,   2 running, 163 sleeping,   0 stopped,   1 zombie
#   Cpu(s):  0.7%us,  0.6%sy,  0.1%ni, 98.3%id,  0.3%wa,  0.0%hi,  0.0%si,  0.0%st
#   Mem:   ${memtotal}k total,   ${memused}k used,   ${memfree}k free,    ${buf}k buffers
#   Swap:  ${swaptotal}k total,   ${swapused}k used,  ${swapfree}k free,   ${cache}k cached\n");
    printf("Tasks: %3d total,   2 running, 163 sleeping,   0 stopped,   1 zombie
Cpu(s):  0.7%%us,  0.6%%sy,  0.1%%ni, 98.3%%id,  0.3%%wa,  0.0%%hi,  0.0%%si,  0.0%%st
Mem:  %8dk total, %8dk used, %8dk free, %8dk buffers
Swap: %8dk total, %8dk used, %8dk free, %8dk cached\n",
    $num, $memtotal, $memused, $memfree, $buf, $swaptotal, $swapused, $swapfree, $cache);

    #print "\n";
    use Term::ANSIColor qw(:pushpop);
    print PUSHCOLOR WHITE ON_BLACK 
        "  PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND \n";
    print POPCOLOR "";
    #print color("reset");
    my $count = 0;

    foreach my $file (@files) {
        my @process;
        my $proc_t = 
            {   "pid" => "", # process id 
                "ppid" => "", # pid of parent process */
                
                "pcpu" => "0", # %CPU usage (is not filled in by readproc!!!) */
                "state" => "", # single-char code for process state (S=sleeping) */
                "utime" => "", # user-mode CPU time accumulated by process */
                "stime" => "", # kernel-mode CPU time accumulated by process */
                # and so on...
                "cutime" => "", # cumulative utime of process and reaped children */
                "cstime" => "", # cumulative stime of process and reaped children */
                "start_time" => "", # start time of process -- seconds since 1-1-70 */
                ## ifdef SIGNAL_STRING
                # char
                # Linux 2.1.7x and up have 64 signals. Allow 64, plus '\0' and padding. */
                "signal" => "", #[18]  mask of pending signals */
                "blocked" => "", #[18]  mask of blocked signals */
                "sigignore" => "", #[18]  mask of ignored signals */
                "sigcatch" => "", #[18]  mask of caught signals */
                ##else
                # long long
                # Linux 2.1.7x and up have 64 signals. */
                # signal, # mask of pending signals */
                # blocked, # mask of blocked signals */
                # sigignore, # mask of ignored signals */
                # sigcatch; # mask of caught signals */
                ##endif
                #long
                "priority" => "", # kernel scheduling priority */
                "timeout" => "", # ? */
                "nice" => "", # standard unix nice level of process */
                "rss" => "", # resident set size from /proc/#/stat (pages) */
                "it_real_value" => "", # ? */
                # the next 7 members come from /proc/#/statm */
                "size" => "", # total # of pages of memory */
                "resident" => "", # number of resident set (non-swapped) pages (4k) */
                "share" => "", # number of pages of shared (mmap'd) memory */
                "trs" => "", # text resident set size */
                "lrs" => "", # shared-lib resident set size */
                "drs" => "", # data resident set size */
                "dt" => "", # dirty pages */
                #unsigned long
                "vm_size" => "", # same as vsize in kb */
                "vm_lock" => "", # locked pages in kb */
                "vm_rss" => "", # same as rss in kb */
                "vm_data" => "", # data size */
                "vm_stack" => "", # stack size */
                "vm_exe" => "", # executable size */
                "vm_lib" => "", # library size (all pages, not just used ones) */
                "rtprio" => "", # real-time priority */
                "sched" => "", # scheduling class */
                "vsize" => "", # number of pages of virtual memory ... */
                "rss_rlim" => "", # resident set size limit? */
                "flags" => "", # kernel flags for the process */
                "min_flt" => "", # number of minor page faults since process start */
                "maj_flt" => "", # number of major page faults since process start */
                "cmin_flt" => "", # cumulative min_flt of process and child processes */
                "cmaj_flt" => "", # cumulative maj_flt of process and child processes */
                "nswap" => "", # ? */
                "cnswap" => "", # cumulative nswap ? */
                "start_code" => "", # address of beginning of code segment */
                "end_code" => "", # address of end of code segment */
                "start_stack" => "", # address of the bottom of stack for the process */
                "kstk_esp" => "", # kernel stack pointer */
                "kstk_eip" => "", # kernel instruction pointer */
                "wchan" => "", # address of kernel wait channel proc is sleeping in */
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
                "ruid" => "", 
                "rgid" => "", # real */
                "euid" => "", 
                "egid" => "", # effective */
                "suid" => "", 
                "sgid" => "", # saved */
                "fuid" => "", 
                "fgid" => "", # fs (used for file access only) */
                "pgrp" => "", # process group id */
                "session" => "", # session id */
                "tty" => "", # full device number of controlling terminal */
                "tpgid" => "", # terminal process group id */
                "exit_signal" => "", # might not be SIGCHLD */
                "processor" => "", # current (or most recent?) CPU */
                ##ifdef FLASK_LINUX
                "sid" => ""
                ##endif
            };
        #$proc_t -> {"pid"} = $file;
        $file = File::Spec->catfile($proc, $file);

        if(! -e $file) {
            next;
        } else {
            #----------/proc/#/stat
            my $fd;
            open($fd, "<", File::Spec->catfile($file, "stat"));
            next unless $fd;
            my $line = <$fd>;
            close $fd;
            
            ( $proc_t->{"pid"}, $proc_t->{"cmd"},$proc_t->{"state"},$proc_t->{"ppid"},
              $proc_t->{"pgrp"}, $proc_t->{"session"}, $proc_t->{"tty"}, 
              $proc_t->{"tpgid"}, $proc_t->{"flags"}, $proc_t->{"min_flt"}, 
              $proc_t->{"cmin_flt"}, $proc_t->{"maj_flt"},
              $proc_t->{"cmaj_flt"}, $proc_t->{"utime"}, $proc_t->{"stime"}, $proc_t->{"cutime"},
              $proc_t->{"cstime"}, $proc_t->{"priority"}, $proc_t->{"nice"},
              $proc_t->{"it_real_value"}, $proc_t->{"timeout"}, # not sure the value what's mean 
              $proc_t->{"start_time"}, $proc_t->{"vsize"},
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
            #----------/proc/#/status
            open($fd, "<", File::Spec->catfile($file, "status"));
                
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
            open($fd, "<", File::Spec->catfile($file, "statm"));

            next unless $fd;
            $line = <$fd>;
            close $fd;

            ( $proc_t->{"size"}, $proc_t->{"resident"}, $proc_t->{"share"},
              $proc_t->{"trs"}, $proc_t->{"lrs"}, $proc_t->{"drs"}, 
              $proc_t->{"dt"} ) = split(/\s+/, $line);

            #----------/proc/cmdline
            open($fd, "<", File::Spec->catfile($file, "cmdline"));

            next unless $fd;
            $line = <$fd>;
            close $fd;
            $proc_t->{"cmdline"} = $line;
            
            #----------/proc/environ
            my $result = open($fd, "<", File::Spec->catfile($file, "environ"));
            if($result) {
                next unless $fd;
                $line = <$fd>;
                close $fd;
                $proc_t->{"environ"} = $line;
            } else {
                $proc_t->{"environ"} = ""; 
            }

            $proc_t->{"euser"} = getpwuid($proc_t->{"euid"});
            $proc_t->{"ruser"} = getpwuid($proc_t->{"ruid"});
            $proc_t->{"suser"} = getpwuid($proc_t->{"suid"});
            $proc_t->{"egroup"} = getgrgid($proc_t->{"egid"});
            $proc_t->{"rgroup"} = getgrgid($proc_t->{"rgid"});
            ## $proc_t
        }

        if($proc_t->{"state"} eq 'Z') {
            $proc_t->{"cmd"} .= " <defunct>"
        }

        if($count < $row) {
    printf("%5s %-8.9s %3s %3s %5.5s %4.4s %4.4s %1s %4.1s %4.1s %9.8s %-15s\n", 
                $proc_t->{"pid"}, $proc_t->{"euser"},
                $proc_t->{"priority"}, $proc_t->{"nice"},
                $proc_t->{"vsize"}, $proc_t->{"resident"},
                $proc_t->{"share"}, $proc_t->{"state"},
                $proc_t->{"pcpu"}, $proc_t->{"vm_size"}, # XXX 
                $proc_t->{"timeout"}, $proc_t->{"cmd"}
            );
            ## $proc_t
            # last;
            $count++;
        } else {
            $count = 0;
            last;
        }
    }

} while (0); 

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

sub mywarn {
    return CORE::warn( _my_program(), ': ', @_, "\n" );
}

sub mydie {
    #return CORE::die( _my_program(), ': ', @_, "\n" );
    print (color("red"), _my_program(), ': ', @_, "\n");
    print color("reset");
    exit;
}

sub _my_program {
    require File::Basename;
    return File::Basename::basename( $0 );
}

sub get_memswap_info() {
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


# Esc[2JEsc[1;1H    - Clear screen and move cursor to 1,1 (upper left) pos.
#define clrscr()              puts ("\e[2J\e[1;1H")
sub clrscr {
    print "\e[2J\e[1;1H";
}

# Esc[K     - Erases from the current cursor position to the end of the current line.
#define clreol()              puts ("\e[K")
sub clreof {
    print "\e[K";
}

# Esc[2K            - Erases the entire current line.
#define delline()             puts ("\e[2K")
sub delline {
    print "\e{2K";
}

# Esc[Line;ColumnH    - Moves the cursor to the specified position (coordinates)
#define gotoxy(x,y)           printf("\e[%d;%dH", y, x)
sub gotoxy {
    my $x = shift;
    my $y = shift;

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

