use strict;
use warnings;

use Test::More tests => 3;

use Monitoring;
use Monitoring::Sendmail;

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

