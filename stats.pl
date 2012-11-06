#!/usr/bin/perl -w

# Copyright (c) 2008 dean gaudet <dean@arctic.org>
# 
# Permission is hereby granted, free of charge, to any person obtaining a
# copy of this software and associated documentation files (the "Software"),
# to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons to whom the
# Software is furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included
# in all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
# OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
# OTHER DEALINGS IN THE SOFTWARE.

use strict;
use warnings;

my $sum = 0;
my $square = 0;
my $n = 0;

my $do_geom = 1;
my $geom = 0;
my $min;
my $max;

while (<>) {
	chomp;
	s#_##g;
	my $x;
	foreach $x (split) {
		next unless $x =~ /^[0-9.+-]+$/;
		$sum += $x;
		$square += $x*$x;
		++$n;
		if ($x <= 0) {
			$do_geom = 0;
		}
		else {
			$geom += log($x);
		}
		$min = $x if (!defined($min) or $x < $min);
		$max = $x if (!defined($max) or $x > $max);
	}
}

my $mean = $sum / $n;
my $sd = sqrt(($square - $sum * $sum / $n) / ($n-1));

if (defined($ENV{'terse'})) {
  printf("count %s min/avg/max %f/%f/%f CV %5.4f%%\n", $n, $min, $mean, $max, 100 * ($sd / $mean));
  exit 0;
}

printf "n:     %10u\n", $n;
printf "total: %15.4f\n", $sum;
printf "mean:  %15.4f\n", $mean;
printf "min:   %15.4f\n", $min;
printf "max:   %15.4f\n", $max;
if ($n > 1) {
        printf "sd:    %15.4f %5.4f%% (coefficient of variation)\n", $sd, 100 * ($sd / $mean);
}

if ($do_geom && $geom != 0) {
	printf "geom:  %15.4f\n", exp($geom/$n);
}
