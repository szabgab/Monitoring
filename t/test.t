use strict;
use warnings;
no warnings 'redefine';

use Test::More tests => 2;
use Test::Deep qw(cmp_deeply re);

use Monitoring;
use Monitoring::Sendmail;

my $DATE = re('^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$');

@ARGV = ( '--config', 't/1.yml' );
my $o = Monitoring->new_with_options;

isa_ok $o, 'Monitoring';
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
	shift;
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

#$o->report;
#diag explain \@reports;

