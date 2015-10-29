use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME         => 'Monitoring',
	AUTHOR       => q{Gabor Szabo <szabgab@cpan.org>},
	VERSION_FROM => 'lib/Monitoring.pm',
	ABSTRACT     => 'Monitoring web sites',
	( $ExtUtils::MakeMaker::VERSION >= 6.3002
		? ( 'LICENSE' => 'perl' )
		: () ),
	PL_FILES  => {},
	PREREQ_PM => {
		'Moo'                            => 0,
		'MooX::Options'                  => 0,
		'autodie'                        => 0,
		'LWP::UserAgent'                 => 0,
		'LWP::Protocol::https'           => 0,
		'POSIX'                          => 0,
		'YAML'                           => 0,
		'Time::HiRes'                    => 0,
		'Text::CSV'                      => 0,
		'Text::CSV_XS'                   => 0,
		'Fcntl'                          => 0,
		'Email::Stuffer'                 => 0,
		'Email::Sender::Transport::SMTP' => 0,
		'Exporter'                       => 0,

		'Test::More'         => 0,
		'Test::Deep'         => 0,
	},
	dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
