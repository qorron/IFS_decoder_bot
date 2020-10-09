#!/usr/bin/perl

use 5.030;
package IFS::Decoder::Solution::Symbol::Portal;
use Moose;
 
with 'IFS::Decoder::Theme';

has 'previous' => ( is => 'rw', isa => 'IFS::Decoder::Solution::Symbol::Portal', );
has 'next'     => ( is => 'rw', isa => 'IFS::Decoder::Solution::Symbol::Portal', );
 
has 'submissions' => (
	traits  => ['Array'],
	is      => 'rw',
	isa     => 'ArrayRef[IFS::Decoder::Solution::Symbol::Portal::Submission]',
	default => sub { [] },
	handles => {
		add             => 'push',
		delete_index    => 'delete',
		has_submissions => 'count',
	},
);

sub delete_submission {}
 
sub best {
	my $self = shift;
	return unless $self->has_submissions;
	return $self->submissions->[-1];
}

sub has_previous {
	my $self = shift;
	return $self->previous && $self->previous->has_submissions;
}

sub has_next {
	my $self = shift;
	return $self->next && $self->next->has_submissions;
}

sub point {
	my $self = shift;
	return unless $self->has_submissions;
	return $self->best->point;
}

sub marker {
	my $self = shift;
	return unless $self->has_submissions;
	my ($color) = @_;
	$color //= '#aaaaaa';
	return {
		color  => $color,
		latLng => $self->point,
		type   => 'marker',
	};
}

sub structure_char {
	my $self = shift;
	return $self->square->{none} unless $self->has_submissions;
	return $self->square->{multi} if $self->has_neighbour;
	return $self->square->{single};
}

sub is_first {
	my $self = shift;
	return !$self->has_previous;
}

sub is_in_chain {
	my $self = shift;
	return !$self->is_first;
}

sub has_neighbour {
	my $self = shift;
	return $self->has_previous || $self->has_next;
}

42;

