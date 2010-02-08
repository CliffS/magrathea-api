package CouchDB::Lite;

use warnings;
use strict;
# use 5.10.0;

use Carp;

use JSON::XS qw();
use REST::Client;
use CouchDB::Lite::Boolean;

use Data::Dumper;

BEGIN {
    use Exporter ();
    our (@ISA, @EXPORT_OK, %EXPORT_TAGS);
    @ISA = qw(Exporter);
    @EXPORT_OK = qw(true false bool);
    %EXPORT_TAGS = (boolean => [@EXPORT_OK]);
}

=head1 NAME

CouchDB::Lite - A simple perl module for CouchDB

=head1 VERSION

Version 0.1.0

=cut

use version 0.80; our $VERSION = version->declare('v0.1.0');

=head1 SYNOPSYS

    use CouchDB::Lite qw(:boolean);

    my $couch = new CouchDB::Lite(
	host	 => $host, 
	db	 => $database,
	user	 => 'cliff',
	password => 'geheim'
    );

    my @databases = $couch->all_dbs;
    $couch->db('sofa'); die unless $couch->ok;
    my $docs = $couch->all_docs({ limit => 20 });
    my $post = $couch->doc('A-test-post'); die unless $couch->ok;
    $couch->doc($post);
    my $view = $couch->view('sofa', 'recent-posts');

This module is designed to be a lightweight interface to CouchDB. Several
other CPAN modules exist with similar functionality but they do not appear
to have been kept up to date.

This module currently supports CouchDB version 0.10 and I shall endeavour
to keep it current as the CouchDB team issues new releases.

It makes heavy use of L<JSON::XS> and all JSON to Perl conversions are
made with this module.  It also relies on L<REST::Client> for access to
the CouchDB server.

=head1 EXPORTS

The module does not export anything by default.  JSON boolean values
are represebted using L<CouchDB::Lite::Boolean> rather than
L<JSON::XS::Boolean> values.  Although the code has been shamelessly
stolen from L<JSON::XS::Boolean> (thanks Marc), the
L<CouchDB::Lite::Boolean> value has the advantage that it stringifies 
to C<"true"> or C<"false">.

If you wish to import the values of L<true|CouchDB::Lite::Boolean/true>,
L<false|CouchDB::Lite::Boolean/false> and L<bool|CouchDB::Lite::Boolean/bool>,
you may use the module in either of the following ways:

    use CouchDB::Lite qw(true false bool);
    use CouchDB::Lite qw(:boolean);

=cut

=for comment

Internal functions with prototypes.

=cut

sub checklocal()
{
    carp "Private Function" if ref $_[0];
}

sub checkdb($)
{
    my $self = shift;
    croak "No database specified" unless $self->{db};
}

=head1 CONSTRUCTOR

=head2 new(%options)

This is the constructor for the CouchDB::Lite object. It takes
an optional hash of options.

The options are:

=over 4

=item host

The host address of the CouchDB server.  Defaults to 'localhost'.

=item port

The port to talk to the CouchDB server on.  Defaults to 5984.

=item user

The username to use for the CouchDB server.

=item password

The password for the user.
Note: Both user and password should be set or neither will be used.

=item db

The database to use.  This may either be set here or using the
$couch->db call later.

=back

=cut

sub new
{
    my $class = shift;
    my %options = @_;
    my $self = {};
    $self->{host} = $options{host} || 'localhost';
    $self->{port} = $options{port} || 5984;
    $self->{json} = new JSON::XS->allow_blessed->convert_blessed;
    my $security = '';
    if ($options{user} && $options{password})
    {
	$security = $options{user} . ':' . $options{password} . '@';
    }
    $self->{db} = $options{db} if $options{db};
    $self->{rest} = new REST::Client({
	    host => $security . "$self->{host}:$self->{port}",
	});
    bless $self, $class;
}

=head1 DATABASE METHODS

=head2 all_dbs

Returns an array containing the names of all databases found on the
server.

=cut

sub all_dbs
{
    my $self = shift;
    my $url = $self->url('_all_dbs');
    return $self->get($url);
}

=head2 db I<or> db($name)

If the optional name parameter is passed, this sets the database to be
used for further operations.

Returns a reference to a hash of the database information
as provided by the server. If no database name has ever been
set then L<$couch-E<gt>ok|/ok> wll be false and the server
welcome message will be returned.

The current database name can be retrieved using:

    my $data = $couch->db;
    my $database_name = $data->{db_name};

=cut

sub db
{
    my $self = shift;
    my $db = shift || $self->{db};
    my $response = $self->get($self->url($db));
    if ($db && $self->{ok})
    {
	$self->{db} = $db;
    }
    else {
	$self->{ok} = false;
    }
    return $response;
}

=head2 new_db($name)

Creates a new database called C<$name>.  Note that C<$name> must
be lower case.

Returns a reference to a hash containing C<< ok => true >>
on success and sets $couch->ok.

On failure, sets $couch->ok to false and returns a hash
contining C<error> and C<reason>.

=cut

sub new_db
{
    my $self = shift;
    my $db = shift;
    $self->{db} = $db;
    my $response = $self->put($self->url($db));
    $self->{ok} = defined $response->{ok} ? true : false;
    return $response;
}

=head2 del_db I<or> del_db($name)

Deletes the named database or the current database if C<$name>
is not passed.  If the database deleted is the current one, this
removes the current database reference from the object.

Returns a reference to a hash containing C<< ok => true >>
on success and sets $couch->ok.

On failure, sets $couch->ok to false and returns a hash
contining C<error> and C<reason>.

=cut

sub del_db
{
    my $self = shift;
    my $db = shift || $self->{db};
    delete $self->{db} if defined $self->{db} && $self->{db} eq $db;
    my $response = $self->delete($self->url($db));
    $self->{ok} = defined $response->{ok} ? true : false;
    return $response;
}

=head1 DOCUMENT METHODS

=head2 all_docs I<or> all_docs(%params)

Calls the C<_all_docs> function of CouchDB.  Possible parameters
include start_key, end_key, limit and descending.

On success, returns a hash containing C<total_rows> as a number and
C<rows> and an array reference.

Croaks if no database has been selected.

=cut

sub all_docs
{
    my $self = shift;
    my %params = @_;
    checkdb $self;
    return $self->get($self->url([$self->{db}, '_all_docs'], \%params));
}

=head2 new_doc(\%document) I<or> new_doc($id, \%document)

This is passed either a document as a hash reference or both an id
as a string and a document as a hash reference.

In the former mode, the document id will be created from a uuid
by the server, in the latter it will be added from the id passed.

This function returns the hash as provided by the server and sets
C<< $couch->ok >>.

=cut

sub new_doc
{
    my $self = shift;
    my $doc = shift;
    my $id;
    unless (ref $doc)
    {
	$id = $doc;
	$doc = shift;
    }
    if ($id)
    {
	$self->put($self->url([$self->{db}, $id]), $doc);
    }
    else {
	$self->post($self->url($self->{db}), $doc);
    }
    # propogated return
}

=head2 doc($key) I<or> doc(\%document)

This is the main document-handling function.  If it is called
with a key as a string, it will try to find the document with that key.
If it is called with a reference to a hash, it will attempt to
replace the document into the database.

When getting a document, it is returned as a hash referebce, if found
and C<< $couch->ok >> is set to C<true>.  If not found, a hrsh reference
of the error is returned containing C<error> and C<reason>. C<< $couch->ok >>
will be false;

When replacing a document, $C<< $couch->ok >> willl be set to true on
success and the returned hash reference will contain the
revision and the ID.  On failure, $C<< $couch->ok >> will be false
and the returned hash reference will contain C<error> and C<reason>.

=cut

sub doc
{
    my $self = shift;
    my $doc = shift;
    if (ref $doc)   # it's an update
    {
	$self->put($self->url([$self->{db}, $doc->{_id}]), $doc);
    }
    else {	    # It's a fetch
	$self->get($self->url([$self->{db}, $doc]));
    }
    # propogated return
}

=head2 delete_doc($key, $revision) I<or> delete_doc(\%document)

This deletes a document from the database.  You may either pass
the key and the revision as strings or you may pass the document
as a hash reference and the key and revision will be taken from the
document.

Returns a hash reference containg the result from the server.

=cut

sub delete_doc
{
    my $self = shift;
    my $doc = shift;
    my ($id, $rev);
    if (ref $doc)
    {
	$id = $doc->{_id};
	$rev = $doc->{_rev};
    }
    else {
	$id = $doc;
	$rev = shift;
    }
    $self->delete($self->url([$self->{db}, $id], {rev => $rev}));
}

=head1 VIEWS METHODS

=head2 temp_view($map, $reduce, \%options)

This will generate a temporary view.  The C<$map> and C<$reduce>
parameters should be strings containing the body of the map and reduce
Javascript functions respectively.  If C<$reduce> is undef, no reduce
function will be created.

=head3 Example:

    my $map = q[ if (doc.foo == 'bar') { emit(null, doc.foo); } ];
    $couch->temp_view($map);

will generate the following map function:

    function(doc)
    {
	if (doc.foo == 'bar') {
	    emit(null, doc.foo);
	}
    }

The return value will be the result of the temporary view, on success
or the error on failure.  C<< $couch->ok >> will containe true or false
respectively.

=cut

sub temp_view
{
    my $self = shift;
    my $map = shift;
    my $reduce = shift;
    my $opts = shift;
    my $view = { map => "function(doc) { $map }" };
    $view->{reduce} = "function(keys,values,rereduce) { $reduce }" if $reduce;
    $self->post($self->url([$self->{db}, '_temp_view'], $opts), $view);
}

=head2 view($designdoc, $view, \%opts)

The C<$designdoc> may incluide the C<_design/> part of the name but
it will be added in if not present.  The C<$view> is a string containing the
name of the view.  Opts is a hash reference of CouchDN standard options.

For example:

    $couch->db('sofa');
    my $view = $couch->view('sofa', 'recent-posts');
    die "View Failed: " . $couch->code unless $couch->ok;

=cut

sub view
{
    my $self = shift;
    (my $design = shift) =~ s[^(_design/)?][_design/];
    my $view = shift;
    my $opts = shift;
    $self->get($self->url([$self->{db}, $design, '_view', $view], $opts));
}

=head1 RESULTS METHODS

=head2 ok

C<< $couch->ok >> returns a L<CouchDB::Boolean> value of true or
false.  C<true> means the last call was successful, C<false> means
an error of some kind occurred.

=cut

sub ok
{
    my $self = shift;
    return $self->{ok};
}

=head2 code

C<< $couch->code >> returns the response code from the the most
recent http request.

=cut

sub code
{
    my $self = shift;
    return $self->{code};
}

=head1 INTERNAL METHODS

These methods should normally not be called from outside of
the CouchDB::Lite module.

=cut

sub response
{
    my $self = shift;
    my $rest = shift;
    $self->{code} = $rest->responseCode;
    $self->{ok} = $rest->responseCode < 300 ? true : false;
    my $json = $self->{json}->decode($rest->responseContent);
    return $json;
}


=head2 get($url)

Perform a REST GET.

=cut

sub get
{
    my $self = shift;
    my $url = shift;
    my $rest = $self->{rest};
    $rest->GET($url);
    $self->response($rest);
}

=head2 put($url, $body)

Perform a REST PUT.

=cut

sub put
{
    my $self = shift;
    my $url = shift;
    my $body = shift;
    my $options = {'Content-Type' => 'application/json'};
    $body = $self->{json}->encode($body) if $body;
    my $rest = $self->{rest};
    $rest->PUT($url, $body, $options);
    $self->response($rest);
}

=head2 post($url, $body)

Perform a REST POST.

=cut

sub post
{
    my $self = shift;
    my $url = shift;
    my $body = shift;
    my $options = {'Content-Type' => 'application/json'};
    $body = $self->{json}->encode($body) if $body;
    my $rest = $self->{rest};
    $rest->POST($url, $body, $options);
    $self->response($rest);
}

=head2 delete($url)

Perform a REST DELETE.

=cut

sub delete
{
    my $self = shift;
    my $url = shift;
    my $rest = $self->{rest};
    $rest->DELETE($url);
    $self->response($rest);
}

=head2 url($path, \%query) I<or> url(\@path, \%query)

This creates a URL for the REST calls passed either the path
as a string or as an array.  The query string (if any) should
be passed as a hash reference.

=cut

# Passed ref array of paths and ref hash of query
sub url
{
    my ($self, $path, $query)  = @_;
    $path = join '/', @$path if ref $path;
    $path = '' unless $path;
    my %queries = %$query if ref $query;
    $query = join '&', map { join '=', ($_, $queries{$_}) } keys %queries;
    my $url = "/$path";
    $url .= "?$query" if $query;
    return $url;
}

=head1 SEE ALSO

L<JSON::XS> JSON serialising/deserialising, done correctly and fast

L<REST::Client> A simple client for interacting with RESTful http/https
resources

=head1 AUTHOR

Cliff Stanford, C<< <cliff@may.be> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-couchdb-lite@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CouchDB-Lite>.  I will
be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CouchDB::Lite

The main documentation for CouchDB can be found at
L<http://wiki.apache.org/couchdb/>

=head1 COPYRIGHT & LICENCE

Copyright 2010 Cliff Stanford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut


1;
