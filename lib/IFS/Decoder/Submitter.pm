#!/usr/bin/perl
use 5.030;
package IFS::Decoder::Submitter;
use Moose;
use Data::Dumper;
 
has 'language_code' => ( is => 'rw', isa => 'Str', );
has 'id'            => ( is => 'rw', isa => 'Int', required => 1, );
has 'is_bot'        => ( is => 'rw', isa => 'Bool', required => 1, );
has 'first_name'    => ( is => 'rw', isa => 'Str', );
has 'last_name'     => ( is => 'rw', isa => 'Str', );
has 'username'      => ( is => 'rw', isa => 'Str', );


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
	$args->{is_bot} = $args->{is_bot} ? 1 : 0;
	return $class->$orig($args);
};
42;

