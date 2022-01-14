#!/usr/bin/perl

use 5.030;
package Telegram::Target::Pattern;
use Moose;

use Data::Dumper;

extends 'Telegram::Target';

around BUILDARGS => sub {
	my $orig  = shift;
	my $class = shift;

	my $args;
	if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
		$args = $_[0];
	}
	else {
		$args = {@_};
	}
	my $pattern = $args->{pattern};
	my $handler = $args->{handler};
	return $class->$orig( pattern => $pattern, handler => $handler );
};

sub handle {
	my $self = shift;
	my ( $captures, $message ) = (@_);

	$self->handler->( $captures, $message );
}

42;

