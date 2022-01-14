#!/usr/bin/perl
use 5.030;
package Telegram::Chat;
use Moose;

use Data::Dumper;
has 'title'                          => ( is => 'rw', isa => 'Str', );
has 'all_members_are_administrators' => ( is => 'rw', isa => 'Bool', );
has 'type'                           => ( is => 'rw', isa => 'Str', required => 1, );
has 'id'                             => ( is => 'rw', isa => 'Int', required => 1, );
    
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
	$args->{all_members_are_administrators} = $args->{all_members_are_administrators} ? 1 : 0;
    return $class->$orig($args);
};  








42;

