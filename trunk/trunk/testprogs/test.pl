#!/usr/bin/perl
#

use strict;
use warnings;
use 5.10.0;

use lib '/home/cliff/src/perl';

use CouchDB::Lite qw(:bool);
use Data::Dumper;

my $c = new CouchDB::Lite(
    user => 'cliff',
    password => 'ph10na'
);

use constant DB => 'perl_database';

#say $c->url([], { a => 'x', b => 'y' });

#print Dumper $c->all_dbs;

#print Dumper $c->db(DB);

#print Dumper $c->all_docs(limit => 2, skip => 20);

#print Dumper $c->del_db(DB), $c->err;
#print Dumper $c->new_db(DB), $c->err;

$c->new_db(DB);

print Dumper $c->new_doc("Hello", { one => 1, two => 2});
my $response = $c->new_doc({ one => 5, two => 6});
print Dumper $response;
say $response->{ok} if $response->{ok};

my $doc = $c->doc('Hello');
print Dumper $doc;
say "one = $doc->{one}";
my %doc = %$doc;
say "\$doc{one} = $doc{one}";
print Dumper $doc, \%doc; exit;
$doc->{new_field} = [ qw(one two three four five) ];
$doc->{hash} = { one => 'not 1 any more', two => 2, three => { a => 'b', c => 'd'}};
$response = $c->doc($doc);
print Dumper $response;
say "Temp view:";
$response = $c->temp_view(
    'emit(doc.one, 1)',
    'return sum(values)',
    {group => true}
);
print Dumper $response, $c->{err};

say "Real View:";

$response = $c->view('_design/temp', 'simple', {group => true});
print Dumper $response, $c->{err};

