# NAME

Magrathea::API - Easier access to the Magrathea NTSAPI

# SYNOPSIS

    use Magrathea::API;
    blah blah blah

# DESCRIPTION

Stub documentation for Magrathea::API, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

## EXPORT

Nothing Exported.

# CLASS FUNCTIONS

## new

This will create a new Magrathea object and open at telnet
session to the server.  If authorisation fails, it will croak.

    my $mt = new Magrathea::API(
        username    => 'myuser',
        password    => 'mypass',
    );

### Parameters:

- username
- password

    The username and password allocated by Magrathea.

- host

    Defaults to _api.magrathea-telecom.co.uk_ but could be overridden.

- port

    Defaults to _777_.

- timeout

    In seconds. Defaults to _10_.

# INSTANCE FUNCTIONS

In all cases where `$number` is passed, this may be a string
containing a number in National format (_020 1234 5678_) or
in International format (_+44 20 1234 5678_).  Spaces are ignored.
Also, [Phone::Number](https://metacpan.org/pod/Phone::Number) objects may be passed.

When a number is returned, it will always be in the for of a
[Phone::Number](https://metacpan.org/pod/Phone::Number) object.

## allocate

Passed a prefix, this will allocate and activate a number.  You do not need
to add the `_` characters.  If a number can be found, this routine
will return a [Phone::Number](https://metacpan.org/pod/Phone::Number) object.  If no match is found, this
routine will return `undef`. It will croak on any other error from
Magrathea.

## allocate10

Passed a prefix, this will allocate and activate a block of 10 numbers.  You do
not need to add the `_` characters.  If a block can be found, this routine
should return an arrayref of ten [Phone::Number](https://metacpan.org/pod/Phone::Number) objects. Under odd
circumstances, it is possible that fewer than ten numbers will be returned;

If no range is foud is found, this routine will return `undef`. It will croak
on any other error from Magrathea.

## fax2email

Sets a number as a fax to email.

    $mt->fax2email($number, $email_address);

## voice2email

Sets a number as a voice to email.

    $mt->voice2email($number, $email_address);

## sip

    $mt->sip($number, $host, [$username, [$inband]]);

Passed a number and a host, will set an inbound sip link
to the international number (minus leading +) @ the host.
I username is defined, it will be used instead of the number.
If inband is true, it will force inband DTMF.  The default is
RFC2833 DTMF.

## iax2

    $mt->iax2($number, $host, $username, $password);

## divert

    $mt->divert($number, $to_number);

## deactivate

Passed a number as a string or a Phone::Number, this deactivate
the number.

## reactivate

Reactivates a number that has previously been deactivated.

## status

Returns the status for a given number.  

    my $status = $mt->status($number);
    my @status = $mt->status($number);

In scalar context, returns the first (and usually only) status as
a [Magrathea::API::Status](https://metacpan.org/pod/Magrathea::API::Status) object.  In list context, returns up to
three statuses representing the three possible setups created with
ORDE.

If the number is not allocated to us and activated, this routine
returns `undef` in scalar context and an empty list in list context.

The [Magrathea::API::Status](https://metacpan.org/pod/Magrathea::API::Status) object has the following calls:

- `$status->number`

    A [Phone::Number](https://metacpan.org/pod/Phone::Number) object representing the number to which this
    status refers.

- `$status->active`

    Boolean.

- `$status->expiry`

    The date this number expires in the form `YYYY-MM-DD`.

- `$status->type`

    One of sip, iax2, fax2email, voice2email, divert or unallocated.

- `$status->target`

    The target email or phone number for this number;

- `$status->entry`

    The entry number (1, 2 or 3) for this status;

In addition, it overloads '""' to provide as tring comprising
the type and the target, separated by a space.

# LOW LEVEL FUNCTIONS

All the Magrathea low level calls are available.  These are
simply passed an array of strings which are joined to create
the command string.  They return the raw response
on success (minus the leading 0) and die on failure.  `$@`
will contain the error.

See the [Magrathea documentation](http://www.magrathea-telecom.co.uk/assets/Client-Downloads/Numbering-API-Instructions.pdf).

The functions are:

- auth

    This is called by ["new"](#new) and should not be called directly.

        $mt->auth('username', 'password');

- quit

    This is called automatically upon the Magrathea::API object
    going out of scope and should not be called directly.

- allo

        $mt->allo('0201235___');

- acti

        $mt->acti('02012345678');

- deac

        $mt->deac('02012345678');

- reac

        $mt->reac('02012345678');

- stat

        $mt->stat('02012345678');

- set

        $mt->set('02012345678 1 441189999999');
        $mt->set('02012345678 1 F:fax@mydomain.com');
        $mt->set('02012345678 1 V:voicemail@mydomain.com');
        $mt->set('02012345678 1 S:username@sip.com');
        $mt->set('02012345678 1 I:username:password@iaxhost.com');

- spin

        $mt->set('02012345678 [pin]');

- feat

        $mt->feat('02012345678 D');
        $mt->feat('02012345678 J');

- orde

        $mt->orde('02012345678 1 0000');

- alten

        $mt->alten('0845________');

- info

        $mt->info('02012345678 GEN Magrathea, 14 Shute End, RG40 1BJ');

It will not usually be necessary to call these functions directly.

# SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

# AUTHOR

Cliff Stanford, <cliff@may.be>

# COPYRIGHT AND LICENSE

Copyright (C) 2012 by Cliff Stanford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
