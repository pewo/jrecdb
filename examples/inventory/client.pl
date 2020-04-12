#!/usr/bin/perl -w

use strict;
use Socket;
use JSON;
use MIME::Base64 qw( encode_base64 decode_base64 );

sub popen($) {
	my($cmd) = shift;
	my(@res) = ();
	if ( open(POPEN,"$cmd |") ) {
		foreach ( <POPEN> ) {
			next unless ( defined($_) );
			chomp;
			push(@res,$_);
		}
	}
	return(@res);
}

sub readf($) {
	my($file) = shift;
	my(@res) = ();
	if ( open(my $fh,"<",$file) ) {
		foreach ( <$fh> ) {
			next unless ( defined($_) );
			chomp;
			push(@res,$_);
		}
		close($fh);
	}
	return(@res);
}
		

sub ip4() {
	my(@addr) = popen("ip addr");
	my(@res) = ();
	foreach (@addr) {
		next unless ( m/inet\s+(\d+\.\d+\.\d+\.\d+)\// );
		next if ( $1 =~ /^127/ );
		push(@res,$1);
	}
	return(@res);
}

my(%inv) = ();

foreach ( ip4() ) {
	my $name = gethostbyaddr(inet_aton($_),AF_INET);
	$inv{ip} = $_;
	$inv{name} = $name;
}

foreach ( readf("/etc/os-release") ) {
	next unless ( m/^VERSION=/ );
	$inv{version} = $_;
}
	
my($uptime) = readf("/proc/uptime");
$uptime =~ s/\D.*//;
$inv{uptime} = $uptime;


my($json);
$json = JSON->new->allow_nonref;
my($json_text);
$json_text   = $json->encode( \%inv );
#print $json_text . "\n";
my($base64);
$base64 = encode_base64($json_text,"");
#print $base64 . "\n";


my($cmd) = "/usr/bin/wget --no-check-certificate -O /dev/null -o /dev/null --quiet 'https://10.0.0.254:4443/dbwrite?jobtype=inventory&secret=inventory";
$cmd .= "&inventory=$base64'";
print $cmd . "\n";
system($cmd);
