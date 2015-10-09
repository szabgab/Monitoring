use strict;
use warnings;

use Test::More tests => 1;

use Monitoring;
use Monitoring::Sendmail;

@ARGV = ('--config', 'minitor-skel.yml');
my $o = Monitoring->new_with_options;

isa_ok $o, 'Monitoring';

