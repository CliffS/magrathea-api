package Magrathea::API;

use strict;
use warnings;
use 5.10.0;

use version 0.77; our $VERSION = qv('v0.9.0');

use Net::Telnet;
use Phone::Number;
use Email::Address;
use Magrathea::API::Status;

use Carp;
use Data::Dumper;
#use Try::Tiny;

our @CARP_NOT = qw{ Net::Telnet }; # Try::Tiny };

#say Dumper \%Carp::Internal, \%Carp::CarpInternal; exit;

use constant DEBUG => 1;
use enum qw{ false true };

=head1 NAME

Magrathea::API - Easier access to the Magrathea NTSAPI

=head1 SYNOPSIS

  use Magrathea::API;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for Magrathea::API, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

Nothing Exported.

=cut

#################################################################
##
##  Local Prototyped Functions
##
#################################################################

sub catch(;$)
{
    my $_ = $@;
    return undef unless $_;
    chomp;
    my $re = shift;
    return true if ref $re eq 'Regexp' and $_ =~ $re;
    croak $_;
}

#################################################################
##
##  Private Instance Functions
##
#################################################################

sub sendline
{
    my $self = shift;
    my $message = shift // '';
    say ">> $message" if DEBUG;
    $self->{telnet}->print($message) if $message;
    my $response = $self->{telnet}->getline;
    chomp $response;
    my ($val, $msg) = $response =~ /^(\d)\s+(.*)/;
    croak qq(Unknown response: "$response") unless defined $val;
    say "<< $msg" if DEBUG;
    die "$msg\n" unless $val == 0;
    return $msg;
}

#################################################################
##
##  Class Functions
##
#################################################################

=head1 CLASS FUNCTIONS

=head2 new

This will create a new Magrathea object and open at telnet
session to the server.  If authorisation fails, it will croak.

    my $mt = new Magrathea::API(
	username    => 'myuser',
	password    => 'mypass',
    );

=head3 Parameters:

=over 1

=item username

=item password

The username and password allocated by Magrathea.

=item host

Defaults to I<api.magrathea-telecom.co.uk> but could be overridden.

=item port

Defaults to I<777>.

=item timeout

In seconds. Defaults to I<10>.

=back

=cut

sub new
{
    my $class = shift;
    my %defaults = (
	host	=> 'api.magrathea-telecom.co.uk',
	port	=> 777,
	timeout	=> 10,
    );
    my %params = (%defaults, @_);
    croak "Username & Password Required"
	    unless $params{username} && $params{password};
    my $telnet = new Net::Telnet(
	Host	=> $params{host},
	Port	=> $params{port},
	Timeout => $params{timeout},
	Errmode	=> sub {
	    croak shift;
	},
    );
    my $self = {
	params	=> \%params,
	telnet	=> $telnet,
    };
    bless $self, $class;
    $self->sendline;
    eval {
	$self->auth(@params{qw(username password)});
    };
    catch;
    return $self;
}

#################################################################
##
##  Instance Functions
##
#################################################################

=head1 INSTANCE FUNCTIONS

In all cases where C<$number> is passed, this may be a string
containing a number in National format (I<020 1234 5678>) or
in International format (I<+44 20 1234 5678>).  Spaces are ignored.
Also, L<Phone::Number> objects may be passed.

When a number is returned, it will always be in the for of a
L<Phone::Number> object.

=head2 allocate

Passed a prefix, this will allocate and activate a number.  You do not need
to add the C<_> characters.  If a number can be found, this routine
will return a L<Phone::Number> object.  If no match is found, this
routine will return C<undef>. It will croak on any other error from
Magrathea.

=cut

sub allocate
{
    my $self = shift;
    my $number = shift;
    $number = substr $number . '_' x 11, 0, 11;
    for (my $tries = 0; $tries < 5; $tries++)
    {
	eval {
	    my $result = $self->allo($number);
	    ($number = $result) =~ s/\s.*$//;
	};
	return undef if catch qr/^No number found for allocation/;
	eval {
	    $self->acti($number);
	};
	unless (catch qr/^Number not activated/)    # $@ is ''
	{
	    return new Phone::Number($number);
	}
    }
    return undef;   # Failed after 5 attempts.
}

=head2 allocate10

Passed a prefix, this will allocate and activate a block of 10 numbers.  You do
not need to add the C<_> characters.  If a block can be found, this routine
should return an arrayref of ten L<Phone::Number> objects. Under odd
circumstances, it is possible that fewer than ten numbers will be returned;

If no range is foud is found, this routine will return C<undef>. It will croak
on any other error from Magrathea.

=cut

sub allocate10
{
    my $self = shift;
    my $range = shift;
    $range = substr $range . '_' x 11, 0, 11;
    my $alloc = eval {
	$self->alten($range);
    };
    return undef if catch qr/^No range found for allocation/;
    $alloc =~ s/\s.*$//;
    die "Odd allocation of $alloc" unless $alloc =~ /^\d+_$/;
    my @numbers;
    foreach (0 .. 9)
    {
	(my $number = $alloc) =~ s/_$/$_/;
	eval {
	    $self->allo($number);
	    $self->acti($number);
	};
	unless ($@)
	{
	    my $object = new Phone::Number($number);
	    push @numbers, $object;
	}
    }
    return \@numbers;
}


=head2 fax2email

Sets a number as a fax to email.

    $mt->fax2email($number, $email_address);

=cut

sub fax2email
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $email = shift;
    my @email = parse Email::Address($email);
    croak "One email address required" if @email != 1;
    $self->set($number->packed, 1, "F:$email[0]");
}

=head2 voice2email

Sets a number as a voice to email.

    $mt->voice2email($number, $email_address);

=cut

sub voice2email
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $email = shift;
    my @email = parse Email::Address($email);
    croak "One email address required" if @email != 1;
    $self->set($number->packed, 1, "V:$email[0]");
}

=head2 sip

    $mt->sip($number, $host, [$username, [$inband]]);

Passed a number and a host, will set an inbound sip link
to the international number (minus leading +) @ the host.
I username is defined, it will be used instead of the number.
If inband is true, it will force inband DTMF.  The default is
RFC2833 DTMF.

=cut

sub sip
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my ($host, $username, $inband) = @_;
    croak "Domain required" unless $host;
    $username = $number->plain unless $username;
    my $sip = $inband ? "s" : "S";
    $self->set($number->packed, 1, "$sip:$username\@$host");
}

=head2 iax2

    $mt->iax2($number, $host, $username, $password);

=cut

sub iax2
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my ($host, $username, $password) = @_;
    $self->set($number->packed, 1, "I:$username:$password\@$host");
}

=head2 divert

    $mt->divert($number, $to_number);

=cut

sub divert
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $to = new Phone::Number(shift);
    $self->set($number->packed, 1, $to->plain);
}


=head2 deactivate

Passed a number as a string or a Phone::Number, this deactivate
the number.

=cut

sub deactivate
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    $self->deac($number->packed);
}

=head2 reactivate

Reactivates a number that has previously been deactivated.

=cut

sub reactivate
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    $self->reac($number->packed);
}

=head2 status

Returns the status for a given number.  

    my $status = $mt->status($number);
    my @status = $mt->status($number);

In scalar context, returns the first (and usually only) status as
a L<Magrathea::API::Status> object.  In list context, returns up to
three statuses representing the three possible setups created with
ORDE.

If the number is not allocated to us and activated, this routine
returns C<undef> in scalar context and an empty list in list context.

The L<Magrathea::API::Status> object has the following calls:

=over

=item C<< $status->number >>

A L<Phone::Number> object representing the number to which this
status refers.

=item C<< $status->active >>

Boolean.

=item C<< $status->expiry >>

The date this number expires in the form C<YYYY-MM-DD>.

=item C<< $status->type >>

One of sip, iax2, fax2email, voice2email, divert or unallocated.

=item C<< $status->target >>

The target email or phone number for this number;

=item C<< $status->entry >>

The entry number (1, 2 or 3) for this status;

=back

In addition, it overloads '""' to provide as tring comprising
the type and the target, separated by a space.

=cut

sub status
{
    my $self = shift;
    my $number = new Phone::Number(shift);
    my $status = eval {
	$self->stat($number->packed);
    };
    return wantarray ? () : undef if $@;
    my @statuses = split /\|/, $status;
    my @retval;
    for my $i (0 .. 2)
    {
	my $stat = new Magrathea::API::Status($statuses[$i]);
	return $stat unless wantarray;
	next unless $stat;
	$stat->entry($i + 1);
	push @retval, $stat;
    }
    return @retval;
}

=head1 LOW LEVEL FUNCTIONS

All the Magrathea low level calls are available.  These are
simply passed an array of strings which are joined to create
the command string.  They return the raw response
on success (minus the leading 0) and die on failure.  C<$@>
will contain the error.

See the L<Magrathea documentation|http://www.magrathea-telecom.co.uk/assets/Client-Downloads/Numbering-API-Instructions.pdf>.

The functions are:

=over

=item auth

This is called by L</new> and should not be called directly.

    $mt->auth('username', 'password');

=item quit

This is called automatically upon the Magrathea::API object
going out of scope and should not be called directly.

=item allo

    $mt->allo('0201235___');

=item acti

    $mt->acti('02012345678');

=item deac

    $mt->deac('02012345678');

=item reac

    $mt->reac('02012345678');

=item stat

    $mt->stat('02012345678');

=item set

    $mt->set('02012345678 1 441189999999');
    $mt->set('02012345678 1 F:fax@mydomain.com');
    $mt->set('02012345678 1 V:voicemail@mydomain.com');
    $mt->set('02012345678 1 S:username@sip.com');
    $mt->set('02012345678 1 I:username:password@iaxhost.com');

=item spin

    $mt->set('02012345678 [pin]');

=item feat

    $mt->feat('02012345678 D');
    $mt->feat('02012345678 J');

=item orde

    $mt->orde('02012345678 1 0000');

=item alten

    $mt->alten('0845________');

=item info

    $mt->info('02012345678 GEN Magrathea, 14 Shute End, RG40 1BJ');

=back

It will not usually be necessary to call these functions directly.

=cut

sub AUTOLOAD
{
    my $self = shift;
    my $commands = qr{^(?:
    AUTH|QUIT|ALLO|ACTI|DEAC|REAC|STAT|SET|SPIN|FEAT|ORDE|ALTEN|INFO
    )$}x;
    (my $name = our $AUTOLOAD) =~ s/.*://;
    (my $cmd = $name) =~ tr/[a-z]/[A-Z]/;
    croak "Unknown Command: $name" unless $cmd =~ $commands;
    return $self->sendline("$cmd @_");
}

sub DESTROY
{
    my $self = shift;
    eval {
	$self->quit;
    };
}

1;

__END__

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Cliff Stanford, E<lt>cliff@may.beE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Cliff Stanford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.

=cut

