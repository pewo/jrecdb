sub collect(%) {
	my(%args) = @_;

	unless ( $args{url} ) {
		die "Missing url\n$usage\n";
	}
	my($uri) = URI->new($url);
	return(undef) unless ( defined($uri) );

	my($scheme) = $uri->scheme;
	return(undef) unless ( defined($scheme) );


   my($bot) = undef;
	if ( $scheme eq "https" ) {

		if ( $args{nocert} ) {
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
		die $response->status_line;
	}

	my($content) = $response->decoded_content();
	return(undef) unless ( $content );

	my($line);
	my($added) = 0;
	my(%local) = ();

	foreach $line ( split(/\n|\r/,$content ) ) {
		next unless ( $line );
		next unless ( $line =~ /record/ );
		chomp($line);

		print "Parsing $line\n" if ( $debug );
		my $json = JSON->new->allow_nonref;
		my $perl_scalar = $json->decode( $line );
		next unless ( defined($perl_scalar) );
		print "JSON: " . Dumper(\$perl_scalar) . "\n" if ( $debug );


		my($client) = $perl_scalar->{client};
		next unless ( defined($client) );
		next unless ( $client =~ /^\d+\.\d+\.\d+\.\d+$/ );
		print "client:$client\n" if ( $debug );
		$local{client} = $perl_scalar->{client};
		delete($perl_scalar->{client});
	
		my($time) = $perl_scalar->{time};
		next unless ( defined($time) );
		next unless ( $time =~ /^\d+$/ );
		print "time:$time\n" if ( $debug );
		$local{time} = $perl_scalar->{time};
		delete($perl_scalar->{time});

		foreach ( sort keys %$perl_scalar ) {
			$local{$_}=$perl_scalar->{$_};
		}
		$local{localtime}=time;
	}
	return(undef) unless ( defined($local{client}) );
	return(\%local);
}
