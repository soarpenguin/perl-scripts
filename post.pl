#!/usr/bin/env perl

use strict;
use LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use JSON::XS;

my $ua = LWP::UserAgent->new;
# set custom HTTP request header fields
my $url = "http://xxxxxxx";

# add POST data to HTTP request body
my %post_data = (
	'jsondata' => {
		'name' => 'OK',
		'result' => '1'
	}
);

my $req = HTTP::Request->new(POST => $url);
#$req->header('Content-Type' => 'application/json');
$req->header('Content-Type' => 'application/x-www-form-urlencoded');

my $json_obj = new JSON::XS;
my $result_str = $json_obj->encode(\%post_data);
print Dumper($result_str);

#$req->content_type('application/x-www-form-urlencoded');
$req->content($result_str);

print Dumper($ua);

my $resp = $ua->request($req);
if ($resp->is_success) {
	print Dumper($resp->content);
} else {
	print "HTTP POST error code: ", $resp->code, "\n";
	print "HTTP POST error message: ", $resp->message, "\n";
}

my $timestamp = int(time());
my $md5string = "$timestamp";
my $md5 = Digest::MD5->new;
$md5->add($md5string);
my $accessToken = $md5->hexdigest;
my $ua=LWP::UserAgent->new;
$ua->timeout(100);

my $req = $ua->post($url,
  [
       "timeStamp"   => "$timestamp"
  ]
);

if ($req->is_success) {
       my $content = $req->content();
       print "$content\n";
} else {
       print $req->status_line, "\n";
       print $req->message;
}
