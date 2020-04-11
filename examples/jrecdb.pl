#!/usr/bin/perl -w
#
use strict;

use FindBin;
use lib $FindBin::Bin;
use Jrecdb;

my(%defaults) = (
	ansible => "/root/unix-env",
	client => undef,
	debug => 0,
	ignoredone => 1,
);

my(%args) = Jrecdb::getopt(\%defaults);

my($job) = new Jrecdb( %args );

$job->doit();
