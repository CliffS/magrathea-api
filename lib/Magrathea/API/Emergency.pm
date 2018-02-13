package Magrathea::API::Emergency;

use strict;
use warnings;
use 5.10.0;

use Carp;

sub new
{
    my $class = shift;
    my $number = shift;
    my $api = caller;
    croak "This package must not be called directly" unless $api eq 'Magrathea::API';
    my $self = {
        number => $number,
    };
    bless $self, $class;
}

1;
