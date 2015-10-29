use strict;
use warnings;
no warnings 'redefine';

use Test::More;
use Test::Deep qw(cmp_deeply re);

use File::Temp qw(tempdir);
use Path::Tiny qw(path);

use Monitoring;
use Monitoring::Sendmail;

plan tests => 4;

#$ENV{EMAIL_SENDER_TRANSPORT} = 'Test';
#my @mails = Email::Sender::Simple->default_transport->deliveries;

my $DATE = re('^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$');

my $dir = tempdir( CLEANUP => 1 );

#diag $dir;

my $config = path('t/1.yml')->slurp_utf8;
$config =~ s{test_report.txt}{$dir/report.txt};
path("$dir/monitor.yml")->spew_utf8($config);

@ARGV = ( '--config', "$dir/monitor.yml", '--collect' );
my $o = Monitoring->new_with_options;

isa_ok $o, 'Monitoring';
is $o->config, "$dir/monitor.yml", 'config';
is $o->cfg->{report_file}, "$dir/report.txt";

my @fake_response_code;
my @results;
my @reports;

sub Fake::Response::code {
	return shift @fake_response_code;
}

sub LWP::UserAgent::get {
	my $url;
	my $response = bless {}, 'Fake::Response';

	return $response;
}

sub Monitoring::save {
	my $self = shift;
	push @results, \@_;
}

sub Monitoring::send_mail {
	shift;
	push @reports, \@_;
}

@fake_response_code = ( 200, 404 );
@results            = ();
@reports            = ();
$o->run;
cmp_deeply \@results, [ [ $DATE, 'http://perlmaven.com/', 200, '0' ], [ $DATE, 'http://codemaven.com/', 404, '0' ] ];

#$o->generate_report;
#diag explain \@reports;

