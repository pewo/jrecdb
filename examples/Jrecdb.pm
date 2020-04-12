package Object;

use strict;
use Carp;

our $VERSION = 'v0.0.1';

sub set($$$) {
        my($self) = shift;
        my($what) = shift;
        my($value) = shift;

        $what =~ tr/a-z/A-Z/;

        $self->{ $what }=$value;
        return($value);
}

sub get($$) {
        my($self) = shift;
        my($what) = shift;

        $what =~ tr/a-z/A-Z/;
        my $value = $self->{ $what };

        return($self->{ $what });
}

sub new {
        my $proto  = shift;
        my $class  = ref($proto) || $proto;
        my $self   = {};

        bless($self,$class);

        my(%args) = @_;

        my($key,$value);
        while( ($key, $value) = each %args ) {
                $key =~ tr/a-z/A-Z/;
                $self->set($key,$value);
        }

        return($self);
}



package Jrecdb;

use strict;
use Carp;
use Data::Dumper;
use File::Path qw(make_path);
use File::Copy;
use File::Basename;
use File::Temp;
use Getopt::Long;
use IO::Socket::SSL;
use JSON;
use URI;
use LWP::UserAgent;
use File::Path qw(make_path);


our $VERSION = 'v0.0.1';
our @ISA = qw(Object);
our $debug = 0;

sub new {
   my $proto = shift;
   my $class = ref($proto) || $proto;
   my $self  = {};
   bless($self,$class);

	my($jobtype) = basename($0);
	$jobtype =~ s/\.pl//;

	my(%defaults) = ( 
		jobtype		=> $jobtype,
		debug			=> $debug,
	);
	my(%hash) = ( %defaults, @_) ;
	$self->set("debug",$hash{debug});
	while ( my($key,$val) = each(%hash) ) {
		my($textval) = $val;
		$textval = "undef" unless ( $val );
		$self->debug(1,"setting $key=[$textval]");
		$self->set($key,$val);
	}

	{
		my($value);
		$value = $self->get("jobtype");
		unless ( defined($value) ) {
			croak("You need to specify 'jobtype' at least...");
		}
		unless ( $value =~ /^\w+$/ ) {
			croak("Bad value for jobtype: $value\n");
		}

	}
	return($self);
}

sub debug() {
	my($self) = shift;
	my($level) = shift;
	my($msg) = shift;

	return unless ( defined($level) );
	unless ( $level =~ /^\d$/ ) {
		$msg = $level;
		$level = 1;
	}
	my($debug) = $self->get("debug");
	my ($package0, $filename0, $line0, $subroutine0 ) = caller(0);
	my ($package1, $filename1, $line1, $subroutine1 ) = caller(1);

	if ( $debug >= $level ) {
		chomp($msg);
		my($str) = "DEBUG($level,$debug,$subroutine1:$line0): $msg";
		print $str . "\n";
		return($str);
	}
	else {
		return(undef);
	}
}

sub doit() {
	my($self) = shift;

	my($job);
	my($run) = 0;
	foreach $job ( $self->collect() ) {
		$run++;
		$self->debug(1,"Job number $run is starting");
		$self->dojob($job);
		$self->debug(1,"Job number $run is done");
	}
}

sub dojob() {
	my($self) = shift;
	my($job) = shift;

	print Dumper($self);
	print Dumper($job);
	
	my($client) = $job->{"client"};
	return(undef) unless ( defined($client) );

	my($jobtype) = $self->get("jobtype");
	my($tmpdir) = $self->get("tmpdir");
	my($logdir) = $self->get("logdir");


	unless ( defined($logdir) ) {
		$logdir = File::Temp->newdir();
		$self->debug(1,"logdir: $logdir");
	}
	unless ( defined($tmpdir) ) {
		$tmpdir = File::Temp->newdir();
		$self->debug(1,"tmpdir: $tmpdir");
	}

	foreach ( $logdir, $tmpdir ) {
		next unless ( defined($_) );
		if ( ! -d $_ ) {
			$self->debug(1,"mkdir($_)");
      	make_path($_, { verbose => 1, mode => 0700 } );
			if ( ! -d $_ ) {
				chdir($_);
				$self->debug(1,"chdir($_): $!");
				print "chdir($_): $!\n";
				return();
			}
		}
	}

	my $log = File::Temp->new(
     TEMPLATE => "$jobtype.XXXXX",
     DIR => $logdir,
     SUFFIX => ".log",
     UNLINK => 0,
	);
	$self->debug(1,"Created log at " . $log->filename);

	my $inv = File::Temp->new(
     TEMPLATE => "$jobtype.XXXXX",
     DIR => $tmpdir,
     SUFFIX => ".inventory",
     UNLINK => 1,
   );
	my($inventory) = $inv->filename;
	$self->debug(1,"Creating inventory at $inventory\n");

	my($start) = time;
	print $log "Starting $0 at " . localtime($start) . "\n" if ( $log );

	print $inv "[$jobtype]\n";

	if ( $log ) {
		print $log "\nInventory at $inventory\n";
		print $log "[$jobtype]\n";
	}
	print $inv $client . "\n";
	print $log $client . "\n" if ( $log );
	close($inv);

	my($ansible) = $self->get("ansible");
	if ( ! -x $ansible ) {
		print "$ansible is not executable\n";
		$self->debug(1,"$ansible is not executable");
		return(undef);
	}
	my($cmd) = "$ansible ";

	if ( $log ) {
		print $log "\nCommand:\n";
		print $log $cmd . "\n";
	}
	$self->debug(1,$cmd);

	# populate environment variables
	foreach ( keys(%ENV) ) {
		if ( $_ =~ /^JRECDB/ ) {
			delete($ENV{$_});
			$self->debug(1,"Removing ENV $_");
		}
	}
	foreach ( sort keys %$job ) {
		my($val) = $job->{$_};
		my($var) = "JRECDB_" . uc($_);
		$ENV{$var}=$val;
		$self->debug(1,"Setting ENV $var=$val");
	}
	$self->debug(1,"Setting ENV JRECDB_INVENTORY=$inventory");
	$ENV{JRECDB_INVENTORY} = $inventory;
	$self->debug(1,"Setting ENV JRECDB_PROGRAM=$ansible");
	$ENV{JRECDB_PROGRAM}= $ansible;


	#
	# Save STDOUT and STDERR
	# 
	open (my $OLD_STDOUT, '>&', STDOUT);	
	open (my $OLD_STDERR, '>&', STDERR);	

	if ( $log ) {
		print $log "\n--- Output start ---\n\n";
		close($log);
		# reassign STDOUT, STDERR
		open (STDOUT, '>>', $log);
		open (STDERR, '>>', $log);
	}

	# ... 
	# run some other code. STDOUT/STDERR are now redirected to log file
	# ...


	system($cmd);

	# done, restore STDOUT/STDERR
	open (STDOUT, '>&', $OLD_STDOUT);
	open (STDERR, '>&', $OLD_STDERR);

	if ( defined($log) ) {
		if ( open($log,">>",$log) ) {
			$self->debug(1,"Appending log at $log");
		}
		else {
			$self->debug(1,"Writing to $log: $!");
		}
	}

	if ( $log ) {
		print $log "\n--- Output end ---\n";
		my($runtime) = time - $start;
		print $log "\nRuntime: $runtime seconds\n";
		print $log "\nDone $0 at " . localtime(time) . "\n";
		close($log);
	}
}

sub getopt {
	my($defaults) = shift;
	return(undef) unless ( defined($defaults) );

	my($localdebug) = undef;
	GetOptions (
        	"ansible=s" => \$defaults->{ansible},
        	"url=s" => \$defaults->{url},
        	"debug:i"  => \$localdebug,
        	"force" => \$defaults->{force},
	) or die("Error in command line arguments\n");

	if ( ! defined($defaults->{ansible}) ) {
		$defaults->{ansible} = $0 . ".sh";
	}
	if ( defined($localdebug) ) {
        	if ( $localdebug < 1 ) {
	                $localdebug++;
		}
        	$defaults->{debug} = $localdebug;
        }
	else {
        	$defaults->{debug} = 0;
	}

	my(%args) = ();
	foreach ( keys(%$defaults) ) {
		my($val) = $defaults->{$_};
		next unless ( defined($val) );
		$args{$_}=$val;
	}
	return(%args);
}

sub collect() {
	my($self) = shift;
	my($url) = $self->get("url");
	my($nocert) = $self->get("nocert");

	unless ( defined($url) )  {
		$self->debug(1,"Missing url...");
		print "Missing url\n";
		return(undef);
	}
	my($uri) = URI->new($url);
	return(undef) unless ( defined($uri) );

	my($scheme) = $uri->scheme;
	return(undef) unless ( defined($scheme) );


   my($bot) = undef;
	if ( $scheme eq "https" ) {

		if ( defined($nocert) ) {
			$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = 0;
		}
		$bot = LWP::UserAgent->new( 
	 		env_proxy => 1, 
	 		keep_alive => 1, 
	 		timeout => 300, 
	 		ssl_opts => { 
		  		verify_hostname => 0, 
		  		SSL_verify_mode => IO::Socket::SSL::SSL_VERIFY_NONE 
	 		},
		); 
	}
	else {
		$bot = LWP::UserAgent->new( 
	 		env_proxy => 1, 
	 		keep_alive => 1, 
		);
	}

	return(undef) unless ( $bot );
	my $response = $bot->get($url);
	unless ($response->is_success) {
		print  $response->status_line;
		$self->debug(1,$response->status_line);
	}

	my($content) = $response->decoded_content();
	return(undef) unless ( $content );

	my($line);
	my($added) = 0;

	my(@jobs) = ();

	foreach $line ( split(/\n|\r/,$content ) ) {
		next unless ( $line );
		next unless ( $line =~ /record/ );
		chomp($line);

		print "Parsing $line\n" if ( $debug );
		my $json = JSON->new->allow_nonref;
		my $perl_scalar = $json->decode( $line );
		next unless ( defined($perl_scalar) );
		print "JSON: " . Dumper(\$perl_scalar) . "\n" if ( $debug );


		my(%job) = ();
		my($client) = $perl_scalar->{client};
		next unless ( defined($client) );
		next unless ( $client =~ /^\d+\.\d+\.\d+\.\d+$/ );
		print "client:$client\n" if ( $debug );
		$job{client} = $perl_scalar->{client};
		delete($perl_scalar->{client});
	
		my($time) = $perl_scalar->{time};
		next unless ( defined($time) );
		next unless ( $time =~ /^\d+$/ );
		print "time:$time\n" if ( $debug );
		$job{time} = $perl_scalar->{time};
		delete($perl_scalar->{time});

		foreach ( sort keys %$perl_scalar ) {
			$job{$_}=$perl_scalar->{$_};
		}
		$job{localtime}=time;
		push(@jobs,\%job);
	}

	return(@jobs);
}

1;
