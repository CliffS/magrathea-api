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
