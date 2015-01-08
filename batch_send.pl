#!/usr/bin/env perl
#

BEGIN {
    use Cwd 'realpath';
    our $curdir;
    $curdir = __FILE__;
    $curdir = realpath($curdir);
    $curdir =~ s/[^\/]+$//;
    ### $curdir
    if (-e "$curdir/lib") {
        unshift @INC, "$curdir/lib/";
    }
}

use strict;
use warnings;

my $script = &my_program();

&main(@ARGV);

sub main {
    print &usage();
}

sub usage {
    return <<EOT
Usage: $script [option]... -s src -d dst hostlist
    -s : Source file for distribution.

    -d : Destination dir or file for distribution.

    -p : Set parallel for distribution.

    -c : Run the command for hostlist.
EOT
}

sub my_program {
    require File::Basename;
    return File::Basename::basename( $0 );
} 
