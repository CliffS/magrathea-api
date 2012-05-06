#!/usr/bin/perl

use strict;
use warnings;
use 5.10.0;

use lib ".";
use Magrathea::API;

use Data::Dumper;

my $mt = new Magrathea::API(
    username	=> 'whitelabel',
    password	=> 'ja7per',
);

say $mt->stat('02036030555');
say $mt->stat('08450045666');
say $mt->stat('08450045667');

my $retval = $mt->allocate10('0845');
say $retval ? 'found: ' . scalar @$retval : 'undef returned';

say $_->formatted foreach @$retval;
say $mt->status($_) foreach @$retval;

$mt->deactivate($_) foreach @$retval;
eval { $mt->deactivate($_) } foreach ('08451540450' .. '08451540459');
eval { $mt->deactivate($_) } foreach ('08451543240' .. '08451543249');
eval { $mt->deactivate($_) } foreach ('08451543480' .. '08451543489');
