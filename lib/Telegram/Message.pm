#!/usr/bin/perl

use 5.030;
package Telegram::Message;
use Moose;
use Telegram::Chat;
use Telegram::User;
use Data::Dumper;
use JSON;

has 'from'       => ( is => 'ro', isa => 'Telegram::User', required => 1, );
has 'chat'       => ( is => 'ro', isa => 'Telegram::Chat', required => 1, );
has 'text'       => ( is => 'ro', isa => 'Str',            required => 1, );
has 'date'       => ( is => 'ro', isa => 'Int',            required => 1, );
has 'message_id' => ( is => 'ro', isa => 'Int',            required => 1, );


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
	for my $bool_arg (qw()) {
	    $args->{is_bot} = $args->{is_bot} ? 1 : 0;
	}
	$args->{from} = Telegram::User->new($args->{from});
	$args->{chat} = Telegram::Chat->new($args->{chat});

    return $class->$orig($args);
};


                             
                             
#                              'text' => 'show 1',
#                              'date' => 1602604979,
#                              'from' => { 
#                                          'id' => 204066609,
#                                          'username' => 'youAreDoingItWrong',
#                                          'is_bot' => bless( do{\(my $o = 0)}, 'JSON::PP::Boolean' ),
#                                          'first_name' => "\x{1d69a}\x{1d69e}\x{1d68a}\x{1d69d}\x{1d69d}\x{1d69b}\x{1d698}",
#                                          'language_code' => 'en'
#                                        }, 
#                              'message_id' => 250,
#                              'chat' => { 
#                                          'title' => 'IFS Decoder test',
#                                          'all_members_are_administrators' => bless( do{\(my $o = 1)}, 'JSON::PP::Boolean' ),
#                                          'type' => 'group',
#                                          'id' => -402559723
#                                        }








42;
