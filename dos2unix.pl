#!/usr/bin/env perl

my $new_file = shift @ARGV;

perl -e 'while (<>){s/\r//; print}' < ${new_file} > ${new_file}.tmp
