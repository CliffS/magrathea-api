use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'CouchDB::Lite',
    AUTHOR              => 'Cliff Stanford <cliff@may.be>',
    VERSION_FROM        => 'lib/CouchDB/Lite.pm',
    ABSTRACT_FROM       => 'lib/CouchDB/Lite.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More'	=> 0,
	'JSON::XS'	=> 0,
	'REST::Client'	=> 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'CouchDB-Lite-*' },
);
