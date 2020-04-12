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

my(%defaults) = (
   logdir => "/tmp/loggy.d/autoprodinstall/2020/04/12",
	url => 'https://smurf.xname.se:4443/dbread?jobtype=autoprodinstall&sha1=bepa',
);

my(%args) = Jrecdb::getopt(\%defaults);

#print Dumper(\%args);
my($job) = new Jrecdb( %args );
$job->doit();
