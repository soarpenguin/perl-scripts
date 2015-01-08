#!/usr/bin/env perl

use lib ".";
use JSON::XS;
use utf8;
use Encode qw/encode decode/;
use encoding "utf8", STDOUT => "gb2312";

my $modulename = shift @ARGV;
my $version = shift @ARGV;
my $file = shift @ARGV;

if ($file) {
        open FILEHD, ">>", "$file";
        *STDOUT = *FILEHD;
}

# usage: perl get_processinfo_by_mod_version.pl "module" "version"
#        perl get_processinfo_by_mod_version.pl "module" "version" >test.txt

# remove the ^M character for the test.txt file. 
# perl -e 'while (<>){s/\r//; print}' < test.txt > unix.txt

my $apiurl = "xxxxxxx";

if($modulename and $version) {
        my $iurl = `curl $apiurl -d moduleInfo="$modulename($version)" 2>/dev/null`;
        $iurl = encode("utf8",decode("gbk",$iurl));
        my $d = decode_json($iurl);

        print "i=$d->{list}[0]->{url}\n";
        #print "$d->{list}[0]->{desc}\n";

        for my $item (@{$d->{list}[0]->{list}}){
                # print $item->{dataName} . "\n";
                if ($item->{dataName} eq "targetDesc") {
                        print "\n$item->{value}\n";
                } elsif ($item->{dataName} eq "stepDesc") {
                        print "$item->{value}\n";
                }
        }
        exit 0;

} else {
        exit 1;
}
