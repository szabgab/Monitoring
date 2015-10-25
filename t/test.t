use strict;
use warnings;

use Test::More tests => 4;

use Monitoring;
use Monitoring::Sendmail;

@ARGV = ('--config', 't/1.yml');
my $o = Monitoring->new_with_options;

isa_ok $o, 'Monitoring';
is $o->config, 't/1.yml';
is $o->cfg->{from}, 'gabor@example.com', 'config from';
is $o->cfg->{to}, 'szabgab@example.com', 'config to';

