#!/usr/bin/perl -w

use strict;
use warnings;
use Getopt::Long;
use File::Basename;

my $index = 0;
my $linenum = 1;
my $script = basename $0;
my $debug = 0;
my ( $number, $tab, $end, $help, $version );
my $myversion = "0.1.0";

my $Usage = " 
Usage: $script [option]... [file]... 
       -n, --[no]number
              number all output lines or disable with [nonumber]

       -E, --show-ends
              display \$ at end of each line

       -T, --show-tabs
              display TAB characters as ^I

       -h, --help 
              display this help and exit

       --version
              output version information and exit
";

GetOptions(
	'number|n!'   => \$number,  #the '!' means can use --[no]number disable -n option
	'show-ends|E' => \$end,
	'show-tabs|T' => \$tab,
	'help|h'      => \$help,
	'version|v'   => \$version,
	'debug|d'     => \$debug  # use for debug, turn on Smart::Comments;
);

if($debug) {
	# use Smart::Comments;
}

my @files = @ARGV;

if($help or $version) {
	if($version) {
		print "$script version $myversion\n";
	}
	&usage();
}

while(my $line = <>)
{
	if($number) {
		printf ("%6d  ", $linenum++);
		if($tab) {
			$line =~ s/\t/\^I/sg;
			if($end) {
				$line =~ s/(\n|\n\r)/\$$1/;
			}
		}
		print $line;
		if(eof) {
			print("--------end of $files[$index] file--------\n");
			$index += 1;
		}
	} else {
		if($tab) {
			$line =~ s/\t/\^I/sg;
			if($end) {
				$line =~ s/(\n|\n\r)/\$$1/;
			}
		}
		print $line;
		if(eof) {
			print("--------end of $files[$index] file--------\n");
			$index += 1;
		}
	}
}

sub usage {
	print $Usage;
	exit;
}

### @files
### $index
### $tab
### @ARGV
### $number
### $help
### $debug

