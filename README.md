## NAME

Magrathea::API - Easier access to the Magrathea NTS API

## VERSION

Version 1.1.2

Please note that this software is currently beta.

## SYNOPSIS

    use Magrathea::API;
    my $mt = new Magrathea::API;
    my $number = $mt->allocate('01792');
    $mt->deactivate($number);
    my @list = $mt->list('01792');
    my @numbers = $mt->block_allocate('01792', 10);
    $mt->fax2email($numbers[2], 'user@host.com');
    $mt->divert($number[3], '+5716027171');
    $emerg = $mt->emergency_info;

## DESCRIPTION

This module implements most of the
[Magrathea NTS API](https://www.magrathea-telecom.co.uk/assets/Client-Downloads/Numbering-API-Instructions.pdf)
in a simple format.

## EXPORT

Nothing Exported.

## MAIN API METHODS

## Constructor

### new

This will create a new Magrathea object and open at telnet
session to the server.  If authorisation fails, it will croak.

    my $mt = new Magrathea::API(
        username    => 'myuser',
        password    => 'mypass',
    );

#### Parameters:

- username
- password

    The username and password allocated by Magrathea.

- host

    Defaults to _api.magrathea-telecom.co.uk_ but could be overridden.

- port

    Defaults to _777_.

- timeout

    In seconds. Defaults to _10_.

- debug

    If set to a true value, this will output the conversation between the API
    and Magrathea's server.  Be careful as this will also echo the username
    and password.

## Allocation Methods 

In all cases where `$number` is passed, this may be a string
containing a number in National format (_020 1234 5678_) or
in International format (_+44 20 1234 5678_).  Spaces are ignored.
Also, [Phone::Number](https://metacpan.org/pod/Phone::Number) objects may be passed.

When a number is returned, it will always be in the for of a
[Phone::Number](https://metacpan.org/pod/Phone::Number) object.

### allocate

Passed a prefix, this will allocate and activate a number.  You do not need
to add the `_` characters.  If a number can be found, this routine
will return a [Phone::Number](https://metacpan.org/pod/Phone::Number) object.  If no match is found, this
routine will return `undef`. It will croak on any other error from
Magrathea.

### deactivate

Passed a number as a string or a [Phone::Number](https://metacpan.org/pod/Phone::Number), this deactivates
the number.

### reactivate

Reactivates a number that has previously been deactivated.

### list

This should be passed a prefix and possibly a quantity (defaulting
to 10.  It will return a sorted random list of available numbers matching
the prefix.  These are returned as an array (or an arrayref) of
[Phone::Number](https://metacpan.org/pod/Phone::Number).  None  of the numbers is allocated by this method.

If none are available, the method will return an empty array.

## Block Methods

### block\_allocate

This should be passed a prefix (without any `_` characters) and an
optional block size (defaulting to 10).  It will attempt to allocate
and activate a block of numbers.

If a block can be found, this routine
should return an array or arrayref of [Phone::Number](https://metacpan.org/pod/Phone::Number) objects. Under odd
circumstances, it is possible that fewer than the requested quantity
of numbers will be returned;

If no range is found is found, this routine will return `undef` in scalar
context or an empty array in list context. It will croak
on any other error from Magrathea.

### block\_info

This should be passed a number (string or [Phone::Number](https://metacpan.org/pod/Phone::Number))
to check whether that number is part of a block.

If it is, the size of the block will be returned in scalar context;
In list context, the response will be an array of all the numbers
in that block.

If it is not a block, this will return `undef` or an empty
array.

### block\_deactivate

This should be passed the first number in a block.  It will
deactivate and return the block of numbers.

### block\_reactivate

This should be passed the first number in a block.  It will
reactivate the block and return the size of the block in scalar
context or an array of the numbers in list context.

If the block is not available, this method will croak.

In testing, this method has never worked correctly.

## Service Methods

### fax2email

Sets a number as a fax to email.

    $mt->fax2email($number, $email_address);

### voice2email

Sets a number as a voice to email.

    $mt->voice2email($number, $email_address);

### sip

    $mt->sip($number, $host, [$username, [$inband]]);

Passed a number and a host, will set an inbound sip link
to the international number (minus leading +) @ the host.
If username is defined, it will be used instead of the number.
If inband is true, it will force inband DTMF.  The default is
RFC2833 DTMF.

### divert

    $mt->divert($number, $to_number);

### status

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

    One of sip, fax2email, voice2email, divert or unallocated.

- `$status->target`

    The target email or phone number for this number;

- `$status->entry`

    The entry number (1, 2 or 3) for this status;

In addition, it overloads '""' to provide as tring comprising
the type and the target, separated by a space.

## Emergency Methods

### emergency\_info

Passed a phone number, this method returns a
[Magrathea::API::Emergency](https://metacpan.org/pod/Magrathea::API::Emergency) object with the current 999
information.

## Low Level Methods

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

- info

        $mt->info('02012345678 GEN Magrathea, 14 Shute End, RG40 1BJ');

It will not usually be necessary to call these functions directly.

## AUTHOR

Cliff Stanford, <cliff@may.be>

## ISSUES

Please open any issues with this code on the
[Github Issues Page](https://github.com/CliffS/magrathea-api/issues).

## COPYRIGHT AND LICENCE

Copyright (C) 2012 - 2018 by Cliff Stanford

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.1 or,
at your option, any later version of Perl 5 you may have available.
