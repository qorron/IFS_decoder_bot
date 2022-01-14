#!/usr/bin/perl
use 5.030;
package Telegram::Reply;
use Moose;
use Encode;

has 'text'       => ( is => 'rw', isa => 'Str', required => 1, );
has 'parse_mode' => ( is => 'rw', isa => 'Str', required => 1, );
has 'chat_id'    => ( is => 'ro', isa => 'Int', required => 1, );

sub to_message {
	my ( $class, $message ) = @_;
	$class->new( chat_id => $message->chat->id, parse_mode => 'HTML', text => '' );
}
sub for_api {
	my $self = shift;
	return {
	text => decode('utf8', $self->text),
	parse_mode => $self->parse_mode,
	chat_id => $self->chat_id,
};
}
42;

