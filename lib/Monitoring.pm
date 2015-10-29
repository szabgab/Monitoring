package Monitoring;
use 5.010;
use Moo;
use MooX::Options;
use autodie;
use Data::Dumper qw(Dumper);
use LWP::UserAgent;
use POSIX qw(strftime);
use YAML qw(LoadFile);
use Time::HiRes qw(time);
use Text::CSV;
use Fcntl qw(:flock SEEK_END);

use Monitoring::Sendmail qw(send_mail);

our $VERSION = '0.01';

option verbose => ( is => 'ro', required => 0, default => 0,   doc => 'Print what we are doing' );
option config  => ( is => 'ro', required => 1, format  => 's', doc => 'Path to configuration YAML file (monitor.yml)' );

has cfg => ( is => 'rw' );

my $SLOW = 1;

sub BUILD {
	my ($self) = @_;

	# TODO: Apparently if we throw an exception here, MooX::Options will call its 'usage'
	# method and will call exit(). We might need a differnt way to indicate missing
	# configuration file and missing configuration fields.

	die q{Config file '} . $self->config . qq{'is missing\n} if not -e $self->config;

	eval { $self->cfg( LoadFile $self->config ) };
	die "Incorrect format of configuration file\n\n$@" if $@;

	my $cfg = $self->cfg;
	for my $field (qw(report_file)) {
		die "Missing configuration parameter '$field'\n" if not defined $cfg->{$field};
	}

	my %url;
	foreach my $site ( @{ $self->cfg->{sites} } ) {
		$site->{slow} = $site->{slow} || $self->cfg->{slow} || $SLOW;
		$url{ $site->{url} } = $site;
	}
	$cfg->{url} = \%url;
}

sub run {
	my ($self) = @_;

	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);

	my $time = strftime '%Y-%m-%dT%H:%M:%S', gmtime();
	foreach my $site ( @{ $self->cfg->{sites} } ) {
		eval {
			$self->_log("Checking site $site->{name} with url $site->{url}");
			my $start_time   = time;
			my $response     = $ua->get( $site->{url} );
			my $end_time     = time;
			my $elapsed_time = int( 1000 * ( $end_time - $start_time ) ) / 1000;
			$self->save( $time, $site->{url}, $response->code, $elapsed_time );
		};
		print STDERR $@ if $@;
	}

	return;
}

sub save {
	my ( $self, @values ) = @_;

	my $csv = Text::CSV->new;
	open my $fh, '>>', $self->cfg->{report_file};
	flock( $fh, LOCK_EX );
	seek( $fh, 0, SEEK_END );
	$csv->combine(@values);
	printf $fh $csv->string . "\n";

	return;
}

sub _log {
	my ( $self, $msg ) = @_;
	say $msg if $self->verbose;
	return;
}

sub generate_report {
	my ($self) = @_;

	my $report_file = $self->cfg->{report_file};
	my $csv = Text::CSV->new( { binary => 1 } ) or die 'Cannot use CSV: ' . Text::CSV->error_diag();
	open my $fh, '<:encoding(utf8)', $report_file or die "$report_file: $!";
	my %last;
	while ( my $row = $csv->getline($fh) ) {
		my ( $date, $url, $status, $elapsed_time ) = @$row;
		$last{$url} = $row;
	}
	close $fh;
	foreach my $url ( keys %last ) {
		if ( $last{$url}[2] != 200 ) {
			send_mail(
				{
					From    => $self->cfg->{from},
					To      => $self->cfg->{to},
					Subject => "$url is not OK",
				},
				{
					text => join '  ',
					@{ $last{$url} },
				}
			);
		}
		elsif ( $last{$url}[3] > $self->cfg->{url}{$url}{slow} ) {
			send_mail(
				{
					From    => $self->cfg->{from},
					To      => $self->cfg->{to},
					Subject => "$url is too slow",
				},
				{
					text => join '  ',
					@{ $last{$url} },
				}
			);
		}
	}
}

1;

