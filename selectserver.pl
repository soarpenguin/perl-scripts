#!/usr/bin/perl -w
#

use IO::Select; 

# Create the receiving socket 
my $s = new IO::Socket ( 
	LocalHost => "localhost", 
	LocalPort => 7070, 
	Proto => 'tcp' 
	Listen => 16, 
	Reuse => 1, 
); 
die "Could not create socket: $!\n" unless $s; 

$read_set = new IO::Select(); # create handle set for reading 
$read_set->add($s); # add the main socket to the set 

my ($ns, $buf); 
while (1) { # forever 
	# get a set of readable handles (blocks until at least one handle is ready) 
	my ($rh_set) = IO::Select->select($read_set, undef, undef, 0); 
	# take all readable handles in turn 
	foreach $rh (@$rh_set) { 
		# if it is the main socket then we have an incoming connection and 
		# we should accept() it and then add the new socket to the $read_set 
		if ($rh == $s) { 
			$ns = $rh->accept(); 
			$read_set->add($ns); 
		} 
		# otherwise it is an ordinary socket and we should read and process the request 
		else { 
			$buf = <$rh>; 
			if($buf) { # we get normal input 
				# ... process $buf ... 
				print "$buf\n";
			} 
			else { # the client has closed the socket 
				# remove the socket from the $read_set and close it 
				$read_set->remove($rh); 
				close($rh); 
			} 
		} 
	} 
}

#my ($ns, $buf); 
#while( $ns = $s->accept() ) { # wait for and accept a connection 
#	while( defined( $buf = <$ns> ) ) { # read from the socket 
#		# do some processing 
#	} 
#} 
close($s);
