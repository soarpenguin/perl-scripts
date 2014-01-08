#!/bin/env perl
#
# Author: soarpenguin <soarpenguin@gmail.com>
# First release May.14 2013
##################################################
# usage of utils.pm, add code like:
#   use lib "path"; #path is the file of utils.pm 
#   use utils;
##################################################

package utils;

use FileHandle;
use Getopt::Long;
use Time::Local qw(timelocal);
use Term::ANSIColor;
use strict;
$|=1;

BEGIN {
    use Exporter();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
    $VERSION = 0.0.1;
    @ISA = qw(Exporter);
    @EXPORT = qw(
    	clrscr clreol delline gotoxy hidecursor showcursor 
        notice warning fatal_warning attention debug_stdout
        __FUNC__ __func__ get_now_time trim
    );
    @EXPORT_OK = qw(&mk_fd_nonblocking &read_rcfile &get_winsize);
}

#read the content of configure file.
sub read_rcfile {
    my $file = shift;

    return unless defined $file && -e $file;

    my @lines;

    open( my $fh, '<', $file ) or die( "Unable to read $file: $!" );
    while ( my $line = <$fh> ) {
        chomp $line;
        $line =~ s/^\s+//;
        $line =~ s/\s+$//;

        next if $line eq '';
        next if $line =~ /^#/;

        push( @lines, $line );
    }
    close $fh;

    return @lines;
}

sub warn {
    my $program = shift;

    return CORE::warn( $program, ': ', @_, "\n" );
}

sub die {
    my $program = shift;

    return CORE::die( $program, ': ', @_, "\n" );
}

# set socket nonblocking.
sub mk_fd_nonblocking {
    use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

    my $fd = shift;
    my $flags = fcntl($fd, F_GETFL, 0)
        or warn "Can't get flags for the fd: $!\n";

    $flags = fcntl($fd, F_SETFL, $flags | O_NONBLOCK)
        or warn "Can't set flags for the fd: $!\n";
}

######################## terminal screen operator ###############
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

# get the size of the terminal.
sub get_winsize {
    require 'sys/ioctl.ph';
    CORE::warn "no TIOCGWINSZ \n" unless defined &TIOCGWINSZ;
    open(my $tty_fh, "+</dev/tty") or CORE::warn "No tty: $!\n";
    my $winsize;
    unless (ioctl($tty_fh, &TIOCGWINSZ, $winsize='')) {
        CORE::warn sprintf "ioctl TIOCGWINSZ (%08x: $!)\n", &TIOCGWINSZ;
    }
    close($tty_fh);

    #my ($col, $row, $xpixel, $ypixel) = unpack('S4', $winsize);
    my ($row, $col) = unpack('S4', $winsize);

    return ($row, $col);
}

# print notice message in color of green.
sub notice {
    my $message = shift;

    print color "green";
    print "$message\n";
    print color "reset";
}

# print warning message in color of yellow.
sub warning {
    my $message = shift;

    print color "yellow";
    print "$message\n";
    print color "reset";
}

# print fatal_warning message in color of red.
sub fatal_warning {
    my $message = shift;

    print color "red";
    print "$message\n";
    print color "reset";
}

# print attention message in color of blue.
sub attention {
    my $message = shift;

    print color "blue";
    print "$message\n";
    print color "reset";
}

# print debug infomation to stderr.
sub debug_stdout
{
    my $debug = shift;

	if ($debug)
	{
		my ($msg) = @_;
		print STDERR "$msg\n";
	}
}

sub get_now_time {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    my $now_time = sprintf("%d.%d.%d %d:%d:%d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

    return "[$now_time]";
}

sub print_error
{
    my ($string,$string2, $file, $line) = @_;
    use File::Basename;
    $file = basename($file);
    chomp $string;

    print STDOUT get_now_time() . $string . "[" . $file . ":" . $line ."]".$string2."\n";

}

# print_log("[Notice][name]","xxxx", __FILE__, __LINE__);
sub print_log
{
    my ($method,$string, $file, $line) = @_;
    use File::Basename;
    $file = basename($file);
    chomp $string;
    my $components = '[Trace][';
    if($method eq 'main'){
        $components .='main]'
    } else{
        $components .= $method."]";
    }
    print STDOUT get_now_time() . $components . "[" . $file . ":" . $line ."]" . $string."\n";
}

sub trim
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

# Retrieve the name of the current function
sub __FUNC__ { (caller(1))[3] . '()' }
# display the name of the current function
sub __func__ { (caller(1))[3] . '(' . join(', ', @_) . ')' }

1;
