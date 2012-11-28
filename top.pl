#!/usr/bin/perl -w
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
use File::Spec;

use Term::ANSIColor;
#print color("red"), "Stop!\n", color("reset");
#print color("green"), "Go!\n", color("reset");

my $script = &_my_program();
my $myversion = '0.1.0';
my $proc = '/proc';
my $delay;

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
    &die("The /proc filesyestem is not mounted, try \$mount /proc");
}

my @files = ();
my $dh;

if(! opendir $dh, $proc) {
    &die("Open the $proc failed");
}

do {
    @files = readdir($dh);
    closedir($dh);

    @files = grep { /^(\d)+$/ } @files;
    my $num = @files;
    my ($memtotal, $memfree, $buf, $cache, 
        $swaptotal, $swapfree) = &get_memswap_info();
    my ($memused, $swapused) = ($memtotal - $memfree, $swaptotal - $swapfree);

    #my $clear_screen = `clear`;
    #print $clear_screen;
    &clrscr();

    print("Tasks: $num total,   2 running, 163 sleeping,   0 stopped,   1 zombie
Cpu(s):  0.7%us,  0.6%sy,  0.1%ni, 98.3%id,  0.3%wa,  0.0%hi,  0.0%si,  0.0%st
Mem:   ${memtotal}k total,   ${swapused}k  used,   ${memfree}k free,    ${buf}k buffers
Swap:  ${swaptotal}k total,   ${swapused}k used,  ${swapfree}k free,   ${cache}k cached\n");

    #print "\n";
    use Term::ANSIColor qw(:pushpop);
    print PUSHCOLOR WHITE ON_BLACK 
        "  PID USER      PR  NI  VIRT  RES  SHR S %CPU %MEM    TIME+  COMMAND \n";
    print POPCOLOR "";
    #print color("reset");

    foreach my $file (@files) {
        $file = File::Spec->catfile($proc, $file);

        #print "$file\n";
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

sub warn {
    return CORE::warn( _my_program(), ': ', @_, "\n" );
}

sub die {
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
        &die("The file of $meminfo not existed!");
    } else {
        my $fd;

        open($fd, "<", $meminfo);
        &die("Failed to open the file $meminfo") unless $fd;

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
# Esc[K             - Erases from the current cursor position to the end of the current line.
#define clreol()              puts ("\e[K")
# Esc[2K            - Erases the entire current line.
#define delline()             puts ("\e[2K")
# Esc[Line;ColumnH    - Moves the cursor to the specified position (coordinates)
#define gotoxy(x,y)           printf("\e[%d;%dH", y, x)
# Esc[?25l (lower case L)    - Hide Cursor
#define hidecursor()          puts ("\e[?25l")
# Esc[?25h (lower case H)    - Show Cursor
#define showcursor()          puts ("\e[?25h")
sub clrscr {
    print "\e[2J\e[1;1H";
}

sub clreof {
    print "\e[K";
}

sub delline {
    print "\e{2K";
}

sub gotoxy {
    my $x = shift;
    my $y = shift;

    printf("\e[%d;%dH", $x, $y);
}


#sub myprint { 
#    print {$fh} @_ 
#}

