#http://perldoc.perl.org/Term/ANSIColor.html

# terminal color tutorials

use Term::ANSIColor;

print color 'bold blue';
print "This text is bold blue.\n";
print color 'reset';
print "This text is normal.\n";
print colored ("Yellow on magenta.", 'yellow on_magenta'), "\n";
print "This text is normal.\n";
print colored ['yellow on_magenta'], 'Yellow on magenta.', "\n";
print colored ['red on_bright_yellow'], 'Red on bright yellow.', "\n";
print colored ['bright_red on_black'], 'Bright red on black.', "\n";
print "\n";

use Term::ANSIColor qw(uncolor);
print uncolor ('01;31'), "\n";
use Term::ANSIColor qw(colorstrip);
print colorstrip '\e[1mThis is bold\e[0m', "\n";
use Term::ANSIColor qw(colorvalid);
my $valid = colorvalid ('blue bold', 'on_magenta');
print "Color string is ", $valid ? "valid\n" : "invalid\n";

use Term::ANSIColor qw(:constants);
print BOLD, BLUE, "This text is in bold blue.\n", RESET;
use Term::ANSIColor qw(:constants);
{
    local $Term::ANSIColor::AUTORESET = 1;
    print BOLD BLUE "This text is in bold blue.\n";
    print "This text is normal.\n";
}

use Term::ANSIColor qw(:pushpop);

print PUSHCOLOR RED ON_GREEN "This text is red on green.\n";
print PUSHCOLOR BRIGHT_BLUE "This text is bright blue on green.\n";
print RESET BRIGHT_BLUE "This text is just bright blue.\n";
print POPCOLOR "Back to red on green.\n";
print LOCALCOLOR GREEN ON_BLUE "This text is green on blue.\n";
print "This text is red on green.\n";
{
    local $Term::ANSIColor::AUTOLOCAL = 1;
    print ON_BLUE "This text is red on blue.\n";
    print "This text is red on green.\n";
}
print POPCOLOR "Back to whatever we started as.\n";

#\033[1;34m     or     \e[1;34m
#Black       	0;30     Dark Gray     	1;30
#Blue        	0;34     Light Blue    	1;34
#Green       	0;32     Light Green   	1;32
#Cyan        	0;36     Light Cyan    	1;36
#Red         	0;31     Light Red     	1;31
#Purple      	0;35     Light Purple  	1;35
#Brown       	0;33     Yellow        	1;33
#Light Gray  	0;37     White         	1;37
#
# -Ends the colour.
#  \033[0m
#  \x1b[0m
#
#- Position the Cursor:
#  \033[<L>;<C>H
#     Or
#  \033[<L>;<C>f
#  puts the cursor at line L and column C.
#- Move the cursor up N lines:
#  \033[<N>A
#- Move the cursor down N lines:
#  \033[<N>B
#- Move the cursor forward N columns:
#  \033[<N>C
#- Move the cursor backward N columns:
#  \033[<N>D
#
#- Clear the screen, move to (0,0):
#  \033[2J
#- Erase to end of line:
#  \033[K
#
#- Save cursor position:
#  \033[s
#- Restore cursor position:
#  \033[u

##################################################################
#!/usr/bin/perl
# Author: Todd Larason <jtl@molehill.org>
# $XFree86: xc/programs/xterm/vttests/256colors2.pl,v 1.1 1999/07/11 08:49:54 dawes Exp $

print "256 color mode\n\n";

# display back ground colors

for ($fgbg = 38; $fgbg <= 48; $fgbg +=10) {

# first the system ones:
    print "System colors:\n";
    for ($color = 0; $color < 8; $color++) {
        print "\x1b[${fgbg};5;${color}m::";
    }
    print "\x1b[0m\n";
    for ($color = 8; $color < 16; $color++) {
        print "\x1b[${fgbg};5;${color}m::";
    }
    print "\x1b[0m\n\n";

# now the color cube
    print "Color cube, 6x6x6:\n";
    for ($green = 0; $green < 6; $green++) {
        for ($red = 0; $red < 6; $red++) {
            for ($blue = 0; $blue < 6; $blue++) {
                $color = 16 + ($red * 36) + ($green * 6) + $blue;
                print "\x1b[${fgbg};5;${color}m::";
            }
            print "\x1b[0m ";
        }
        print "\n";
    }

# now the grayscale ramp
    print "Grayscale ramp:\n";
    for ($color = 232; $color < 256; $color++) {
        print "\x1b[${fgbg};5;${color}m::";
    }
    print "\x1b[0m\n\n";

}

print "Examples for the 3-byte color mode\n\n";

for ($fgbg = 38; $fgbg <= 48; $fgbg +=10) {

# now the color cube
    print "Color cube\n";
    for ($green = 0; $green < 256; $green+=51) {
        for ($red = 0; $red < 256; $red+=51) {
            for ($blue = 0; $blue < 256; $blue+=51) {
                print "\x1b[${fgbg};2;${red};${green};${blue}m::";
            }
            print "\x1b[0m ";
        }
        print "\n";
    }

# now the grayscale ramp
    print "Grayscale ramp:\n";
    for ($gray = 8; $gray < 256; $gray+=10) {
        print "\x1b[${fgbg};2;${gray};${gray};${gray}m::";
    }
    print "\x1b[0m\n\n";

}
