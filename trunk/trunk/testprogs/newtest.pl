#!/usr/bin/perl
#

use strict;
use warnings;
use 5.10.0;

use lib '/home/cliff/src/perl';

use CouchDB::Lite qw(:bool);
use Data::Dumper;

sub sayerr($$)
{
    my ($couch, $msg) = @_;
    printf "%-11s ok=%s, code=%d\n", "$msg:", $couch->ok, $couch->code;
}

my $couch = new CouchDB::Lite(
    user => 'cliff',
    password => 'ph10na'
);

use constant DB => 'perl_database';

# say $couch->url([], { a => 'x', b => 'y' });

print Dumper $couch->all_dbs;

$couch->db(DB);
sayerr $couch, 'db';

print Dumper $couch->new_doc('728c6c7da8f43feca175e0585461d1s8', { mydoc => 'experiment' });
sayerr $couch, 'new_doc';

my $doc = $couch->doc('728c6c7da8f43feca175e0585461d1s8');
print Dumper $doc;
sayerr $couch, 'doc';

my $val = $couch->doc($doc);
print Dumper $val;
sayerr $couch, 'doc';
print Dumper $couch->doc($doc);
sayerr $couch, 'doc';

print Dumper $couch->delete_doc($doc->{_id}, $val->{rev});
sayerr $couch, 'delete_doc';

$couch->db('sofa');
my $view = $couch->view('sofa', 'recent-posts');
die "View Failed: " . $couch->code unless $couch->ok;
print Dumper $view;
