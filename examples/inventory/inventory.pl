#!/usr/bin/perl -w

use strict;
use Data::Dumper;
use MIME::Base64;
use JSON;

use File::Spec ();
use File::Basename ();
my $path;

BEGIN {
    $path = File::Basename::dirname(File::Spec->rel2abs($0));
    if ($path =~ /(.*)/) {
        $path = $1;
    }
}
use lib $path;
use Jrecdb;

#{
#   "md5" : "mmGynTGXHa99SDUg",
#   "sha1_hex" : "0c0e8f420a05d1d5cf8200833d6ae4bb5761081c",
#   "sha1" : "mmGynTGXHa99SDUg",
#   "md5_hex" : "28cac0b5e605382788ec9fbc32832084"
#}

my(%defaults) = (
	url => 'https://10.0.0.254:4443/dbread?jobtype=inventory&remove=1&secret=inventory',
);

my(%args) = Jrecdb::getopt(\%defaults);

#print Dumper(\%args);
my($job) = new Jrecdb( %args );
my(@jobs) = $job->collect();

foreach ( @jobs ) {
	my($inventory) = $_->{inventory};
	next unless ( defined($inventory) );
	my($decoded);
	$decoded = decode_base64($inventory);
	next unless ( defined($decoded) );

	my($json);
	$json = JSON->new->allow_nonref;

	my($perl_scalar);
	$perl_scalar = $json->decode( $decoded );

	#
	# Update central inventory using the data
	#
	print Dumper(\$perl_scalar);
}


