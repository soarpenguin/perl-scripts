#!/usr/bin/perl -w
#

use strict;

#my $commond;

#$commond = (@ARGV ? $ARGV[0] : "perl");
#print "$commond\n";

my $version = `perl -v | grep "version"`;
#print "$version\n";

if($version eq "") {
	print $version = 0;
#} elsif($version =~ /v?(\d)+\W(\d)+\W(\d)/) {
} elsif($version =~ /((\d)+)\W((\d)+)\W((\d)+)/) {
	print "$1\.$3\.$5\n";
	$version = $&; #$1...$n is the match words or (), all match is $&;
} else {
	$version = 0;
}

print "The perl version is: $version\n";
