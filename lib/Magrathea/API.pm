package Magrathea::API;

use strict;
use warnings;
use 5.10.0;

use Net::Telnet;
use Phone::Number;

use Carp;
use Data::Dumper;

use constant DEBUG => 1;

my $commands = qr{
^AUTH|QUIT|ALLO|ACTI|DEAC|REAC|STAT|SET|SPIN|FEAT|ORDE|ALTEN|GEN$
}x;

#################################################################
##
##  Local Prototyped Functions
##
#################################################################

#################################################################
##
##  Private Functions
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
    croak $response unless $response =~ /^0\s+(.*)/;
    say "<< $1" if DEBUG;
    return $1;
}

#################################################################
##
##  Class Functions
##
#################################################################

sub new
{
    my $class = shift;
    my %defaults = (
	host	=> 'api.magrathea-telecom.co.uk',
	port	=> 777,
	timeout	=> 10,
    );
    my %params = (@_, %defaults);
    croak "Username & Password Required"
	    unless $params{username} && $params{password};
    my $telnet = new Net::Telnet(
	Host	=> $params{host},
	Port	=> $params{port},
	Timeout => $params{timeout},
    );
    my $self = {
	params	=> \%params,
	telnet	=> $telnet,
    };
    bless $self, $class;
    $self->sendline;
    $self->auth(@params{qw(username password)});
    return $self;
}

sub AUTOLOAD
{
    my $self = shift;
    my $commands = qr{
    ^AUTH|QUIT|ALLO|ACTI|DEAC|REAC|STAT|SET|SPIN|FEAT|ORDE|ALTEN|GEN$
    }x;
    (my $name = our $AUTOLOAD) =~ s/.*://;
    $name =~ tr/[a-z]/[A-Z]/;
    croak "Unknown Command: $name" unless $name =~ $commands;
    return $self->sendline("$name @_");
}

sub DESTROY
{
    my $self = shift;
    $self->quit;
}

1;
