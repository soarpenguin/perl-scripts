#!/usr/bin/perl
#### takes a time from command line and shows the difference from the time now
#### author: entropond date: Mon Aug 16 09:40:22 MST 2010

### packages
use Time::ParseDate;

my $DEBUG;
STUFFHAPPENS: {
### arguments
    my $timein;
    if (@ARGV) {
        for (@ARGV) {
            if (s/-d//) { $DEBUG = 1; }
        }
        $timein = join(' ', @ARGV);
    } else {
        print "feed me a time!";
    }

### calculate
    my %time = (
        epoch_seconds   => (),
        junk            => (),
        istimepast      => (),
        elapsed_seconds => (),
    );
    %time = get_elapsed_seconds($timein);
    my %elapsed_ydhms = seconds_to_ydhms($time{elapsed_seconds});

### print
    print_debug ($timein, \%time) if $DEBUG;
    print_it(\%elapsed_ydhms, \%time);
}

sub get_elapsed_seconds ($) {
    my $timein = shift;
    my %time;
    ($time{epoch_seconds}, $time{junk}) = parsedate("$timein");
    if ($time{epoch_seconds} eq "") { die "can't parse your input: \t$timein \nparsedate junk: \t$time{junk}\n"; }

    my $epoch_timenow = time;
    if ($epoch_timenow > $time{epoch_seconds}) {
        $time{istimepast} = "in the past";
        $time{elapsed_seconds} = $epoch_timenow - $time{epoch_seconds};
    }
    else {
        $time{istimepast} = "in the future";
        $time{elapsed_seconds} = $time{epoch_seconds} - $epoch_timenow;
    }
    return %time;
}

sub seconds_to_ydhms ($) {
    my $elapsed_seconds = shift;
    my $s = $elapsed_seconds;
    my ($y, $d, $h, $m);
    my %elapsed_ydhms = ();
    while ($s >= 31536000) { ++$y; $s -=31536000; }
    while ($s >= 86400)    { ++$d; $s -=86400;    }
    while ($s >= 3600)     { ++$h; $s -=3600;     }
    while ($s >= 60)       { ++$m; $s -=60;       }
    $elapsed_ydhms{string} = sprintf("%d years %d days %d hours %d minutes %d seconds", $y, $d, $h, $m, $s);
    $elapsed_ydhms{years}  = $y;
    $elapsed_ydhms{days}   = $d;
    $elapsed_ydhms{hours}  = $h;
    $elapsed_ydhms{minutes}= $m;
    $elapsed_ydhms{seconds}= $s;
    return %elapsed_ydhms;
}

sub print_debug {
    my ($timein, $time_hashref) = @_;
    printf "%-22s %s \n", "input:",                 $timein;
    printf "%-22s %s \n", "parsedate junk:",        $time_hashref->{junk};
    printf "%-22s %s \n", "epoch-offset-seconds:",  $time_hashref->{epoch_seconds};
    printf "%-22s %s \n", "elapsed seconds:",       $time_hashref->{elapsed_seconds};
    print "\n";
}

sub print_it {
    my ($elapsed_ydhms_hashref, $time_hashref) = @_;
    print "$elapsed_ydhms_hashref->{string} $time_hashref->{istimepast}";
    print "\n";
}

