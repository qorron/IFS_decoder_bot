#!/usr/bin/perl

use 5.030;
package IFS::Decoder::Solution::Symbol::Portal::Submission;
use Moose;
 
has 'note' => (
    is      => 'rw',
    isa     => 'Str',
    default => '',
);

has 'submitter' => (
    is      => 'rw',
    isa     => 'Telegram::User',
	required => 1,
);
 
has 'lat' => (
    is      => 'rw',
    isa     => 'Num',
	required => 1,
);
	
has 'lng' => (
    is      => 'rw',
    isa     => 'Num',
	required => 1,
);

has 'submission_time' => (
    is      => 'ro',
    isa     => 'Str',
    default => sub { time }
);

sub point {
	my $self = shift;
	return { lat => $self->lat, lng => $self->lng };
}

sub to_string {
	my $self = shift;
	return 'https://intel.ingress.com/intel?pll='.$self->lat.','.$self->lng;
}

42;

