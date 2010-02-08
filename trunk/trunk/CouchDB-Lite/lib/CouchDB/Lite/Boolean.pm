package CouchDB::Lite::Boolean;

use warnings;
use strict;
# use 5.10.0;

=head1 NAME

CouchDB::Lite::Boolean - JSON Boolean values for CouchDB

=head1 VERSION

Version 0.1.0

=cut

use version 0.80; our $VERSION = version->declare('v0.1.0');

=head1 SYNOPSIS

This is a support module for CouchDB::Lite.  It should not be
imported directly into your program.  If you wish to import
values for L</true>, L</false> and L</bool>, you should use

    use CouchDB::Lite qw(:boolean);

=cut

use JSON::XS;

BEGIN {
    use Exporter ();
    our $VERSION = 0.1;
    our @ISA = qw(Exporter);
    our @EXPORT = qw(true false bool);
}

use overload
   "0+"    => sub { ${$_[0]} },
   "++"    => sub { $_[0] = ${$_[0]} + 1 },
   "--"    => sub { $_[0] = ${$_[0]} - 1 },
   '""'    => sub { ${$_[0]} ? 'true' : 'false'},
   fallback => 1;

our $true  = do { bless \(my $dummy = 1), "CouchDB::Lite::Boolean" };
our $false = do { bless \(my $dummy = 0), "CouchDB::Lite::Boolean" };

=head1 VALUES

=over

=item true

A true JSON value

=cut

sub true()  { $true  }

=item false

A false JSON value

=cut

sub false() { $false }

=back

=head1 METHODS

=over

=item bool

Returns L</true> if the first parameter is a L<CouchDB::Lite::Boolean>
or a L<JSON::XS::Boolean>, otherwise L</false>.

=back

=cut

sub bool($) {
    UNIVERSAL::isa($_[0], 'CouchDB::Lite::Boolean') or
    UNIVERSAL::isa($_[0], 'JSON::XS::Boolean') ? true : false
}


=head1 AUTHOR

Cliff Stanford, C<< <cliff@may.be> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-couchdb-lite-boolean@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=CouchDB-Lite>.
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc CouchDB::Lite::Boolean

=head1 COPYRIGHT & LICENCE

Copyright 2010 Cliff Stanford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
