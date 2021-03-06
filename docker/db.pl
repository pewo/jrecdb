#!/usr/bin/perl -wT
################################################################
#
# db.pl
# 
# This script is used for 3 different tasks in the webserver
#
# dbwrite.pl: write a database record using JSON
#
# dbread.pl: read a database record ( and maybe delete )
#
# digest.pl: encrypt a password to either md5 or sha-1
#
################################################################
use strict;
use File::Temp;
use File::Basename;
use JSON;
use CGI;
use Digest::SHA qw(sha1_hex);
use Digest::MD5 qw(md5_hex);
use Data::Dumper;

my(@encryption_methods) = ( "sha1", "md5" );

my($debug) = 1;
{
	my $fh = undef;

	sub debug($) {
		return() unless ( $debug );
		my($str) = shift;
		return(undef) unless(defined($str));
		chomp($str);
		unless ( $fh ) {
			my($log) = "/tmp/debug.log";
			unlink($log);
			open($fh,">>",$log);
		}

		if ( $fh ) {
			print $fh "DEBUG: $str\n"
		}
	}
}


sub cgi() {
	my($q) = CGI->new;
	print $q->header();

	my(%reserved_keys) = (
		rm => 1,
		remove => 1,
	);
	my(%reserved) = ();

	my $newlevel = File::Temp->safe_level( File::Temp::HIGH );
	die "Could not change to high security" if $newlevel != File::Temp::HIGH;

	my($template) = "jrecdb";
	my($tempdir) = "/tmp/jrecdb";
	my($extension) = "log";

	mkdir($tempdir) unless ( -d $tempdir );
	my $mode = 0700;
	chmod($mode, $tempdir);

	my($script) = $ENV{SCRIPT_NAME};
	debug("script=$script");
	next unless ( defined($script) );
	$script =~ s/\W/_/g;

	my(@names);
	@names = $q->param;
	my(%names) = ();
	my($key) = undef;
	my($size) = 0;
	foreach $key ( @names ) {
		next unless ( defined($key) );
		next unless ( $key =~ /^\w+$/ );
		$key = lc($key);
		$size += length($key);

		my($val);
		$val = $q->param($key);
		next unless ( defined($val) );
		next unless ( $val =~ /^\w+$/ );
		$size += length($val);

		exit(1) if ( $size > 10000 );

		if ( defined($reserved_keys{$key}) ) {
			$key = "remove" if ( $key eq "rm" );
			debug("setting reserved_key $key to $val");
			$reserved{$key}=$val
		}
		else {
			$names{$key} = $val;
			debug("setting [$key] to [$val]");
		}

	}
	
	if ( $script =~ /^_digest$/ ) {
		print "<PRE>\n";
		my(%res) = ();
		foreach ( @encryption_methods ) {
			my $text = $q->param("$_");
			next unless ( defined($text) );
			$res{$_}=$text;
			my($encrypted) = undef;
			if ( $_ eq "sha1" ) {
				$res{"sha1_hex"}= sha1_hex($text);
			}
			elsif ( $_ eq "md5" ) {
				$res{"md5_hex"}= md5_hex($text);
			}
		}
		my $json = JSON->new->allow_nonref;
		print $json->pretty->encode( \%res );
		print "</PRE>\n";
	}
	elsif ( $script =~ /^_dbread$/ ) {
		debug("we are doing a database read");
		my $remove = 0;
		if ( defined($reserved{remove}) ) {
			$remove = 1;
		}
		debug("remove=$remove");

		print "<PRE>\n";
		my($rec) = 0;


		my($dh) = undef;
		unless ( opendir($dh, $tempdir)) {
       			die "Can't open $tempdir $!";
		}


		my(@files) = ();
		while ( my $file = readdir $dh) {
			next unless ( defined($file) );
			next if ( $file eq "." or $file eq ".." );
			if ( $file =~ /(^$template\.\w+\.$extension)/ ) {
				push(@files,$tempdir . "/" . $1);
				debug("Adding $file to readers digest");
			}
		}
		closedir $dh;



		my(@delete) = ();
		foreach ( @files ) {
			my $json = JSON->new->allow_nonref;
			debug("Trying to read file $_");
			$rec++;
			unless ( open(IN,"<",$_) ) {
				print "Reading $_: $!\n";
				debug("Reading $_: $!");
				next;
			}

			my($line);
			$line = <IN>;
			close(IN);
			chomp($line);
			debug("date=[" . $line . "]");
			my($perl_scalar);
			$perl_scalar = $json->decode( $line );
			next unless ( defined($perl_scalar) );

			my($key);
			my($send) = 0;
			my(%required) = ( "secret" => 1, "password" => 1, "md5" => 1, "sha1" => 1 );
			#
			# Loop over argument and match in saved file
			# if we dont find, let the file be...
			#
			foreach $key ( keys %names ) {
				next unless ( defined($key) );
				debug("key: $key");

				if ( defined($required{$key}) ) {
					debug("key $key is a required key, checking it later");
					next;
				}
				my($val) = $names{$key};
				next unless ( defined($val) );
				debug("val: $val");
				my($comp) = $perl_scalar->{$key};
				unless ( defined($comp) ) {
					$send = 0;
					debug("nothing to compare with send=$send");
					last;
				}
				debug("comp $comp");
				if ( lc($val) eq lc($comp) ) {
					$send = 1;
					debug("$comp and $val is equial send=$send");
				}
				else {
					$send = 0;
					debug("$comp and $val is NOT equial send=$send");
					last;
				}
			}
			# no keys found
			next unless ( $send ); 

			#
			# Check for required clear text and encrypted passwords
			# 
			foreach $key ( sort keys %required ) {
				my($val) = $perl_scalar->{$key};
				next unless ( defined($val) );
				debug("$key is defined to $val");

				my($comp) = $names{$key};
				unless ( defined($comp) ) {
					$send = 0;
					debug("nothing to compare with send=$send");
					last;
				}

				my($digest) = undef;
				if ( $key eq "sha1" ) {
					$digest = sha1_hex($comp);
					debug("digest(sha1) = $digest");
				}
				elsif ( $key eq "md5" ) {
					$digest = md5_hex($comp);
					debug("digest(md5) = $digest");
				}
				else {
					$digest = $comp;
					debug("digest(plain) = $digest");
				}

				if ( $val eq $digest ) {
					$send = 1;
					debug("$digest and $val is equial send=$send");
				}
				else {
					$send = 0;
					debug("$digest and $val is NOT equial send=$send");
					last;
				}
			}
			next unless ( $send );

			$perl_scalar->{record}=$rec;
			my($json_text);
			$json_text   = $json->encode( $perl_scalar );
			print $json_text . "\n";

			if ( $reserved{remove} ) {
				debug("removing file $_");
				unlink($_);
			}
		}
		print "</PRE>\n";
	}
	elsif ( $script =~ /^_dbwrite$/ ) {
		debug("we are doing a database write");

		my($client) = $q->remote_addr();
		exit(0) unless ( defined($client) );
		exit(0) unless ( $client =~ /^\d+\.\d+\.\d+\.\d+$/ );
		$names{client}=$client;
		$names{time}=time;

		my $log = File::Temp->new(
			TEMPLATE => $template . ".XXXXX",
			DIR => $tempdir,
			SUFFIX => ".$extension",
			UNLINK => 0,
		);

		my $json = JSON->new->allow_nonref;
		my $json_text   = $json->encode( \%names );

		print $log $json_text . "\n";
		close($log);
		my $mode = 0666;
		chmod($mode, $log);
		print "<PRE>\n";
		print $json->pretty->encode( \%names );
		print "</PRE>\n";

		return(0);
	}
}

delete @ENV{qw(PATH IFS CDPATH ENV BASH_ENV)};   # Make %ENV safer
my($GATEWAY_INTERFACE) = $ENV{GATEWAY_INTERFACE};
if ( defined($GATEWAY_INTERFACE) && $GATEWAY_INTERFACE =~ /CGI/ ) {
	foreach ( sort keys %ENV ) {
		debug(sprintf("%30s -> %s",$_,$ENV{$_}));
	}
	exit(cgi());
}
exit(1);
