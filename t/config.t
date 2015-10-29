use strict;
use warnings;

use Test::More tests => 1;

use Monitoring;
#use Monitoring::Sendmail;

subtest one => sub {
	plan tests => 2;

	@ARGV = ('--config', 't/1.yml');
	my $o = Monitoring->new_with_options;

	is $o->config, 't/1.yml';
	is_deeply $o->cfg, {
       'report_file' => 'test_report.txt',
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
};

# see comment in BUILD of Monitoring.pm
#subtest two => sub {
#	plan tests => 1;
#
#	@ARGV = ('--config', 't/2.yml');
#	Monitoring->new_with_options;
#	ok 1;
#};

