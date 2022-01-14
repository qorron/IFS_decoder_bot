#!/usr/bin/perl
use 5.030;
package Telegram::Target;
use Moose;

use Data::Dumper;

has 'pattern'       => ( is => 'ro', isa => 'RegexpRef', required => 1, );
has 'handler'       => ( is => 'ro', isa => 'CodeRef', required => 1, );

sub handle { ... }
sub handles {
	my $self = shift;
	my ($message) = (@_);
	my @groups;
	my %named;
	if ( @groups = $message->text =~ $self->pattern ) {
		return {%+} if keys %+;
		return \@groups;
	}
	return;
}
42;

