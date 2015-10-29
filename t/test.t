use strict;
use warnings;
no warnings 'redefine';

use Test::More tests => 4;
use Test::Deep qw(cmp_deeply re);

use Monitoring;
use Monitoring::Sendmail;

my $DATE = re('^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d$');

@ARGV = ('--config', 't/1.yml');
my $o = Monitoring->new_with_options;

isa_ok $o, 'Monitoring';
is $o->config, 't/1.yml';
is_deeply $o->cfg, {
   'from' => 'gabor@example.com',
   'sites' => [
     {
       'name' => 'Perl Maven',
       'slow' => 1,
       'url' => 'http://perlmaven.com/'
     },
     {
       'name' => 'Code Maven',
       'slow' => 4,
       'url' => 'http://codemaven.com/'
     }
   ],
   'to' => 'szabgab@example.com'
}, '1.yml configuration file';

my @fake_response_code;
my @results;

sub LWP::UserAgent::get {
	my $url;
	my $response = bless {}, 'Fake::Response';
	sub Fake::Response::code {
		return shift @fake_response_code;
	}
	return $response;
}

sub Monitoring::save {
	shift;
	push @results, \@_;
}

@fake_response_code = (200, 404);
@results = ();
$o->run;
cmp_deeply \@results, [
  [
    $DATE,
    'http://perlmaven.com/',
    200,
    '0'
  ],
  [
    $DATE,
    'http://codemaven.com/',
    404,
    '0'
  ]
]

