#!/usr/bin/env perl
#

BEGIN {
    use Cwd 'realpath';
    our $curdir;
    $curdir = __FILE__;
    $curdir = realpath($curdir);
    $curdir =~ s/[^\/]+$//;
    ### $curdir
    #push @INC, "$curdir/lib/";
}

