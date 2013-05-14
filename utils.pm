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
    @EXPORT = qw(&mk_fd_nonblocking &clrscr &clreol &delline
        &gotoxy &hidecursor &showcursor);
}

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

