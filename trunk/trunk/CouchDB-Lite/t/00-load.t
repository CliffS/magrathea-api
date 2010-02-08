#!perl -T

use Test::More tests => 2;

BEGIN {
	use_ok( 'CouchDB::Lite' );
	use_ok( 'CouchDB::Lite::Boolean' );
}

diag( "Testing CouchDB::Lite $CouchDB::Lite::VERSION, Perl $], $^X" );
