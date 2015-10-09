package Monitor;
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

option verbose => (is => 'ro', required => 0, default => 0, doc => 'Print what we are doing');
option config => (is => 'ro', required => 1, format => 's', doc => 'Path to configuration YAML file (monitor.yml)');
my $report_file = 'report.txt';

sub run {
	my ($self) = @_;


	my $ua = LWP::UserAgent->new;
	$ua->timeout(10);
	my $csv = Text::CSV->new;

	die "Config file '" . $self->config . "'is missing\n" if not -e $self->config;

	my $config = eval { LoadFile $self->config };
	die "Incorrect format of configuration file\n\n$@" if $@;

	my $time = strftime '%Y-%m-%dT%H:%M:%S', gmtime();
	foreach my $site (@{ $config->{sites} }) {
		eval {
			$self->_log("Checking site $site->{name} with url $site->{url}");
			my $start_time = time;
			my $response = $ua->get( $site->{url} );
			my $end_time = time;
			my $elapsed_time = int (1000 * ($end_time-$start_time)) / 1000;
			open my $fh, '>>', $report_file;
			flock($fh, LOCK_EX);
			seek($fh, 0, SEEK_END);
			$csv->combine($time, $site->{url}, $response->code, $elapsed_time);
			printf $fh $csv->string . "\n";
		};
		print STDERR $@ if $@;
	}

	return;
}

sub _log {
	my ($self, $msg) = @_;
	say $msg if $self->verbose;
	return;
}

sub report {
	my ($self) = @_;

	my $csv = Text::CSV->new ( { binary => 1 } ) or die "Cannot use CSV: ".Text::CSV->error_diag ();
	my $config = eval { LoadFile $self->config };
	open my $fh, "<:encoding(utf8)", $report_file or die "$report_file: $!";
	my %last;
	while ( my $row = $csv->getline( $fh ) ) {
		my ($date, $url, $status, $elapsed_time) = @$row;
		$last{$url} = $row;
	}
	close $fh;
	foreach my $url (keys %last) {
		if ($last{$url}[2] != 200) {
			send_mail( {
					From    => $config->{from},
					To      => $config->{to},
					Subject => "$url is not OK",
				},
				{
            		text => join '  ', @{ $last{$url} },
				}
			);
		} elsif ($last{$url}[3] > 4) {
			send_mail( {
					From    => $config->{from},
					To      => $config->{to},
					Subject => "$url is too slow",
				},
				{
            		text => join '  ', @{ $last{$url} },
				}
			);
		}
	}
}


1;

