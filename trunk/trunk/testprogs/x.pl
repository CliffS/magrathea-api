#!/usr/bin/perl
#

use strict;
use warnings;
use 5.10.0;

use lib '/home/cliff/src/perl';

use CouchDB::Lite qw(:bool);
use Data::Dumper;

my $x = true;
say "true = $x";
$x = false;
say "false = $x";
$x = true; $x--;
say "odd = $x";
my $s = \1;
say "\\1 = $s";
$x = true;
say bool $x ? 'yes' : 'no';
say bool $x;
say bool $s ? 'yes' : 'no';
say bool $s;


my $j = new JSON::XS->pretty;

my $c = new CouchDB::Lite;
say $c->url('_all_docs', {query => true});
