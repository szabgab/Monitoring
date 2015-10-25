use strict;
use warnings;

use Test::More tests => 2;

use Monitoring;
use Monitoring::Sendmail;

@ARGV = ('--config', 't/1.yml');
my $o = Monitoring->new_with_options;

isa_ok $o, 'Monitoring';
is $o->config, 't/1.yml';


