#!/usr/bin/env perl
#

use strict;
use warnings;
use Getopt::Long;
use File::Basename;
use threads;
use threads::shared;
use Data::Dumper;

my $script = &my_program();
my $retry = 5;

my $usage = "
Usage: $script [option]...

       -c file, --configure file 
            Configure file for provide the service list and configure file
            name to update.

       -o file, --oldconf file
            Configure file to be replaced.

       -t num, --total num 
            Total number of services of every classfication.

       -p num, --paral num 
            Parallel limited of every classfication.

       -r num, --retry num 
            Number of retries when the update failed.

       -h, --help 
            Display this help and exit.

";

&main();

=begin main
    @parameters
=end
=cut
sub main {
    my ($conffile, $services, $oldconffile, $total, $parallel);
    $conffile = "update.conf";
    $oldconffile = "oldupdate.conf";
    $total = 50;
    $parallel = 10;

    my $ret = GetOptions( 
        'configure|c=s' => \$conffile,
        'oldconf|o=s'   => \$oldconffile,
        'total|t=i'     => \$total,
        'paral|p=i'     => \$parallel,
        'retry|r=i'     => \$retry,
        'help|h'        => \&usage
    );

    $| = 1;

    if(! $ret) {
        &usage();
    }

    if(! $conffile or ! -e $conffile) {
        print "Please provide the configue file for read service list.\n";
        exit 1;
    }
    
    if(! $oldconffile) {
        $oldconffile = $conffile;
    }

    my @threadpool = ();
    
    $services = &read_configure($conffile);
    # print Dumper(\%{$services});

    while(my ($key, $value) = each(%{$services})) {
        print "$key => $value\n";
        my $thr = threads->create(\&update, $parallel, $total, $key, $value, $oldconffile); 
        push @threadpool, $thr;
    }

    foreach my $elem (@threadpool) {
        $elem->join();
    }

    print "done.\n";
}

=begin update
    @parameters
=end
=cut
sub update {
    my ($parallel, $total, $service, $conffile, $oldconffile) = @_;
    my $clusternum = $total / $parallel;
    my @threadpool = ();

    for(my $idx = 1; $idx <= $parallel; $idx++) {
        #&updateconf($idx, $clusternum, $service, $conffile, $oldconffile);
        my $t = threads->create(\&updateconf, $idx, $clusternum, 
                                    $service, $conffile, $oldconffile);
        push @threadpool, $t;
    }
    
    foreach my $elem (@threadpool) {
        $elem->join();
    }
}

=begin updateconf
    @parameters
=end
=cut
sub updateconf {
    my ($idx, $clusternum, $service, $conffile, $oldconffile) = @_;
    my @params = @_;
    my $user = `whoami`;
    my $end = $idx * $clusternum;
    my $start = $end - $clusternum;
    my ($prefix, $suffix) = split /\./, $service;

    $end -= 1;
    chomp($user);

    for (my $idx = $start; $idx <= $end; $idx++) {
        print "$idx:";
        my $times = $retry;
        my $host = "$user\@${prefix}$idx.$suffix:$oldconffile";

        my $ret = &remote_scp($conffile, $host);
        
        while($ret == 0 and $times > 0) {
            $ret = &remote_scp($conffile, $host);
            --$times;
        }
    }
}

=begin remote_scp
    @parameters
=end
=cut
sub remote_scp {
    my ($nconf, $oconf) = @_;

    print "scp $nconf $oconf\n";
    `scp $nconf $oconf >/dev/null 2>&1`;
    
    return $?;
}

=begin read_configure
    @parameters
=end
=cut
sub read_configure {
    my $file = shift;
    my %services = ();

    open(my $fd, "<", $file);
    if(!$fd) {
        return undef;
    }

    while(<$fd>) {
        my ($service, $conf) = split(/\s+/, $_);

        $services{"$service"} = $conf;
    }

    close($fd);
    return \%services;
}

=begin my_program
    @parameters
=end
=cut
sub my_program {
    require File::Basename;
    return File::Basename::basename( $0 );
}

=begin usage
    @parameters
=end
=cut
sub usage {
    print $usage;
    exit;
}
