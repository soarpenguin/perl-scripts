#!/usr/bin/env perl
#
# Author: soarpenguin <soarpenguin@gmail.com>
# First release Jan.3 2014
##################################################
# usage of iputils.pm, add code like:
#   use lib "path"; #path is the file of iputils.pm 
#   use iputils;
##################################################

package iputils;

use FileHandle;
use Getopt::Long;
use Time::Local qw(timelocal);
use Term::ANSIColor;
use strict;
$|=1;

BEGIN {
    use Exporter();
    use vars qw($VERSION @ISA @EXPORT @EXPORT_OK);
    $VERSION = 0.0.1;
    @ISA = qw(Exporter);
    @EXPORT = qw(
        validate_ip ip2long long2ip ip2hex hex2ip
        __FUNC__ __func__ get_now_time trim
    );
    @EXPORT_OK = qw(&mk_fd_nonblocking &get_winsize);
}

use constant true => 1;
use constant false => 0;
use constant MAX_IP => 0xffffffff;
use constant MIN_IP => 0x0;

sub validate_ip {
    my $ip = shift;
    my @array = ();

    return false unless $ip;
    
    $ip = trim($ip);
    if ($ip =~ /^(\d+\.){3}(\d+)$/) {
        @array = split(/\./, $ip);
        foreach my $i (@array) {
             if ($i > 255 || $i < 0) {
                return false;
             }
        }
        return true;
    }
    return false;
}

sub ip2long {
    my $ip = shift;
    my $long = 0;
    
    my $ret = validate_ip($ip);
    if ($ret == false) {
        return $long;
    }
    
    my @array = split(/\./, $ip);
    foreach my $e (@array) {
        $long = ($long << 8 | $e);
    }
    
    return $long;
}

sub long2ip {
    my $l = shift;

    return "0.0.0.0" unless $l;

    if ($l > MAX_IP or $l < MIN_IP) {
        return "0.0.0.0";
    }
    
    return sprintf("%d.%d.%d.%d", 
        $l >> 24 & 255, $l >> 16 & 255, $l >> 8 & 255, $l & 255);
}

sub ip2hex {
    my $netip = shift;

    return "0.0.0.0" unless $netip;
    $netip = ip2long($netip);

    return sprintf("%08x", $netip);
}

sub hex2ip {
    my $netip = shift;

    #$netip = sprintf("%08x", $netip);

    return long2ip($netip);
}

# set socket nonblocking.
sub mk_fd_nonblocking {
    use Fcntl qw(F_GETFL F_SETFL O_NONBLOCK);

    my $fd = shift;
    my $flags = fcntl($fd, F_GETFL, 0)
        or warn "Can't get flags for the fd: $!\n";

    $flags = fcntl($fd, F_SETFL, $flags | O_NONBLOCK)
        or warn "Can't set flags for the fd: $!\n";
}

sub get_now_time {
    my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
    my $now_time = sprintf("%d.%d.%d %d:%d:%d", $year + 1900, $mon + 1, $mday, $hour, $min, $sec);

    return "[$now_time]";
}

sub trim
{
    my $string = shift;
    $string =~ s/^\s+//;
    $string =~ s/\s+$//;
    return $string;
}

# Retrieve the name of the current function
sub __FUNC__ { (caller(1))[3] . '()' }
# display the name of the current function
sub __func__ { (caller(1))[3] . '(' . join(', ', @_) . ')' }

1;
