#!/usr/bin/perl

use 5.030;
package Telegram::Router;
use Moose;
use Telegram::Chat;
use Telegram::User;
use Telegram::Message;
use Telegram::Reply;
use Data::Dumper;
use JSON;

has 'targets' => (
	traits  => ['Array'],
	is      => 'rw',
	isa     => 'ArrayRef[Telegram::Target]',
	default => sub { [] },
	handles => { add_target => 'push', },
);

# sub add_target {
# 	my $self = shift;
# 	my ( $command, $handler ) = @_;
# 	my $target = Telegram::Target->new( pattern => qr(^/$command\b), handler => $handler );
# 	$self->add_target($target);
# }
# sub add_command {
# 	my $self = shift;
# 	my ( $command, $handler ) = @_;
# 	my $target = Telegram::Target->new( pattern => qr(^/$command\b), handler => $handler );
# 	$self->add_target($target);
# }
# sub add_1num_arg_command {
# 	my $self = shift;
# 	my ( $command, $handler ) = @_;
# 	my $target = Telegram::Target->new( pattern => qr(^/$command\d+\b), handler => $handler );
# 	$self->add_target($target);
# }

sub route {
	my $self = shift;
	my ($message) = @_;
	my @answers;
	my $captures;
	for my $target ($self->targets->@*) {
		if ($captures = $target->handles($message)) {
			# warn $target->handle($captures, $message);
			push @answers,
				Telegram::Reply->new(
				text       => $target->handle($captures, $message),
				chat_id    => $message->chat->id,
				parse_mode => 'HTML',
				);
		}
	}
	return \@answers;
}	

42;

