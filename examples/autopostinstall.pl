#!/usr/bin/perl -w

use strict;
use Data::Dumper;

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
   logdir => "/tmp/loggy.d/autopostinstall/2020/04/12",
	url => 'https://smurf.xname.se:4443/dbread?jobtype=autopostinstall&remove=1&sha1=mmGynTGXHa99SDUg',
);

my(%args) = Jrecdb::getopt(\%defaults);

#print Dumper(\%args);
my($job) = new Jrecdb( %args );
$job->doit();
