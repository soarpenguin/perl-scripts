#!/usr/bin/env perl

use POSIX;
use strict;

sub daemonize {
   POSIX::setsid or die "setsid: $!";
   my $pid = fork ();
   if ($pid < 0) {
      die "fork: $!";
   } elsif ($pid) {
      exit 0;
   }
   chdir "/";
   umask 0;
   foreach (0 .. (POSIX::sysconf (&POSIX::_SC_OPEN_MAX) || 1024))
      { POSIX::close $_ }
   open (STDIN, "</dev/null");
   open (STDOUT, ">/dev/null");
   open (STDERR, ">&STDOUT");
}

&daemonize();

while (1) {
        sleep 2;
}
