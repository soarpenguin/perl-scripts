#!/bin/env perl
#
##################################################
# usage of utils.pm, add code like:
#   use lib "path"; #path is the file of utils.pm 
#   use utils;
##################################################

package utils;

use FileHandle;
use Getopt::Long;
use Time::Local qw(timelocal);
use strict;
$|=1;

BEGIN {
    use Exporter();
    use vars qw($VERSION @ISA @EXPORT);
    @ISA = qw(Exporter);
    @EXPORT = qw(&read_rcfile &mk_fd_nonblocking &clrscr &clreol &delline
        &gotoxy &hidecursor &showcursor &get_winsize);
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
