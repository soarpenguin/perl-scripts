#!/usr/bin/perl -w
#
use Socket qw(PF_INET SOCK_STREAM pack_sockaddr_in inet_aton);

socket(my $socket, PF_INET, SOCK_STREAM, 0)
	or die "socket: $!";

my $port = getservbyname "echo", "tcp";
connect($socket, pack_sockaddr_in($port, inet_aton("localhost")))
	or die "connect: $!";

print $socket "Hello, world!\n";

print <$socket>;

#use IO::Socket;
#my $sock = new IO::Socket::INET (
#	 LocalHost => 'thekla',
#	 LocalPort => '7070', 
#	 Proto => 'tcp', 
#	 Listen => 1, 
#	 Reuse => 1, 
#); 
#
#die "Could not create socket: $!\n" unless $sock;
