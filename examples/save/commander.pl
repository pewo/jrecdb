#!/usr/bin/perl -w
#
use strict;
use LWP::Simple;
use Data::Dumper;
use URI;
use Getopt::Long;
use File::Path qw(make_path);
use JSON;

use LWP::UserAgent;
use IO::Socket::SSL;

my($url) = undef;
my($jobdir) = "/var/tmp/job.d";
my($debug) = 0;
my($force) = undef;

GetOptions (
	"url=s" => \$url,    
	"jobdir=s"   => \$jobdir,
   "debug"  => \$debug,
   "force"  => \$force,
 
) or die("Error in command line arguments\n");

my($usage) = "Usage: $0 --url=<url> --jobdir=<directory> --debug --force\n";

unless ( $url ) {
	die "Missing url\n$usage\n";
}
unless ( $jobdir ) {
	die "Missing jobdir\n$usage\n";
}


$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
my $bot = LWP::UserAgent->new( 
    env_proxy => 1, 
    keep_alive => 1, 
    timeout => 300, 
    ssl_opts => { 
        verify_hostname => 0, 
        SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE 
    },
); 
my $response = $bot->get($url);
unless ($response->is_success) {
	die $response->status_line;
}
    
my($content) = $response->decoded_content();
unless ( $content ) {
	print "Nothing to do, exiting...\n";
	exit(1);
}

my($line);
my($added) = 0;
foreach $line ( split(/\n|\r/,$content ) ) {
	next unless ( $line );
	next unless ( $line =~ /record/ );
	chomp($line);

	print "Parsing $line\n" if ( $debug );
	my $json = JSON->new->allow_nonref;
	my $perl_scalar = $json->decode( $line );
	next unless ( defined($perl_scalar) );
	print "JSON: " . Dumper(\$perl_scalar) . "\n" if ( $debug );

	
	my(%local) = ();
	my($client) = $perl_scalar->{client};
	next unless ( defined($client) );
	next unless ( $client =~ /^\d+\.\d+\.\d+\.\d+$/ );
	print "client:$client\n" if ( $debug );
	$local{client} = $perl_scalar->{client};
	delete($perl_scalar->{client});

	my($command) = $perl_scalar->{command};
	next unless ( defined($command) );
	next unless ( $command =~ /^\w+$/ );
	print "command:$command\n" if ( $debug );
	$local{command} = $perl_scalar->{command};
	delete($perl_scalar->{command});

	my($time) = $perl_scalar->{time};
	next unless ( defined($time) );
	next unless ( $time =~ /^\d+$/ );
	print "time:$time\n" if ( $debug );
	$local{time} = $perl_scalar->{time};
	delete($perl_scalar->{time});

	unless ( -d $jobdir ) {
		make_path($jobdir, { verbose => 1, mode => 0755, });
	}
	my($donedir) = $jobdir . "/done";
	unless ( -d $donedir ) {
		make_path($donedir, { verbose => 1, mode => 0755, });
	}
	my($cmdfile) = "client." . $client . "." . $command . ".cmd";
	my($jobfile) = $jobdir . "/" . $cmdfile;

	print "jobfile $jobfile\n" if ( $debug );
	if ( -r $jobfile and not defined($force) ) {
		print "Client has already initated a $command ($jobfile exists)\n";
		print "use --force to force cmdfile overwrite\n";
		next;
	}

	foreach ( sort keys %$perl_scalar ) {
		$local{$_}=$perl_scalar->{$_};
	}
	$local{localtime}=time;

	unlink($jobfile);
	if ( open(my $fh,">>",$jobfile) ) {
		my $json = JSON->new->allow_nonref;
		my $json_text   = $json->encode( \%local );
		print $fh $json_text;
		close($fh);
	}
	$added++;
}
		
if ( $added ) {
	exit(0);
}
exit(1);
