#!/usr/bin/env perl

# replaceMatchLine.pl {{{1
#
# Author:  soarpenguin
#          First release Oct.7 2013
# 1}}}

if (@ARGV != 3) {
    print "perl $0 origfile replfile destfile.\n";
    exit 1;
}

my ($original, $replace, $destfile) = @ARGV;

if (! -e $destfile) {
    die "Please check the destfile for operation.";    
}

open(OFH, "<", $original) or die "open $original file failed.";
open(RFH, "<", $replace) or die "open $original file failed.";

my @orig = <OFH>;
my @rep = <RFH>;

close(OFH);
close(RFH);

if (scalar @orig != scalar @rep) {
    print "The file of $original and $replace line num not matched.\n";
    exit 1;
}

my $count = 0;

# deal with the dest file.
foreach (@orig) {

    chomp($orig[$count]);
    chomp($rep[$count]);
    
    &replace($orig[$count], $rep[$count], $destfile);

    $count++;
}

# grep dest file and replace the match line.
sub replace {
    my $orig = shift;
    my $rep = shift;
    my $dest = shift;

    if ( ! -e $orig or ! defined($orig) ) {
        print "please check the orig file of $orig\n";
        exit 1;
    } elsif ( ! -e $rep or ! defined($rep) ) {
        print "please check the replace file of $rep\n";
        exit 1;
    } elsif ( ! -e $dest or ! defined($dest) ) {
        print "please check the dest file of $dest\n";
        exit 1;
    }

    `fgrep "${orig}" ${dest} &>/dev/null`;
    if($? eq 0) {
        `sed -e "s/\<${orig}\>/${rep}/" ${dest} >${dest}.tmp`;
        `mv ${dest}.tmp ${dest}`;
    } else {
        print "Mismatch the line of $orig\n";    
    }
}
 
