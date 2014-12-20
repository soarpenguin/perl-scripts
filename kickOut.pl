#!/usr/bin/env perl

# kickOut.pl -- a tool script for kicked out the users. {{{1
#   use the cmd "w" and "who am i" get user info.
#   use the cmd "pkill -KILL -t user" kicked out user.
#
# Author:  soarpenguin <soarpenguin@gmail.com>
#          First release Dec.8 2013
# 1}}}

use Term::ANSIColor;

my $DEBUG = 0;
if ($DEBUG) {
    eval q{
        use Smart::Comments;
    };
    die $@ if $@;
}

# get the current user.
my $me = `who am i`;
(undef, $me) = split(/\s+/, $me);
### $me

# get all users current logged.
my @other=`w`;
my $user;

print color("blue"), "Kicked out all users?\n", color("reset");
print "Input(yes/no):";
my $answer = <STDIN>;
if ($answer !~ /y|Y|YES|yes/) {
    exit 0;
}

for(my $i = 2; $i < @other; $i++) {
    (undef, $user) = split(/\s+/, $other[$i]);
    if ($user !~ /pts/) {
        ### $user
        next;
    } elsif ($user =~ /$me/) {
        ### $user
        next;
    } else {
        ### $user
        `pkill -KILL -t $user`;
        if ($? != 0) {
            print "Kill the $user failed.\n";
        }
    }
}

