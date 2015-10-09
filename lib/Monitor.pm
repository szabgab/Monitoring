package Monitor;
use 5.010;
use Moo;
use MooX::Options;
use autodie;
use LWP::UserAgent;
use POSIX qw(strftime);
use YAML qw(LoadFile);
use Time::HiRes qw(time);
use Text::CSV;
use Fcntl qw(:flock SEEK_END);

option verbose => (is => 'ro', required => 0, default => 0, doc => 'Print what we are doing');
option config => (is => 'ro', required => 1, format => 's', doc => 'Path to configuration YAML file (monitor.yml)');

sub run {
	my ($self) = @_;

	my $report_file = 'report.txt';

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


1;

