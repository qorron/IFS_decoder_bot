#!/usr/bin/perl

use 5.030;
package IFS::Decoder::Solution::Symbol;
use Moose;
use List::Util qw(all any);
use JSON;

with 'IFS::Decoder::Theme';
 
has 'type'          => ( is => 'rw', isa => 'Str' );
has 'solution'      => ( is => 'rw', isa => 'Str' );
has 'solution_note' => ( is => 'rw', isa => 'Str' );
has 'portal_count'  => ( is => 'ro', isa => 'Int', required => 1, );
 
has 'portals' => (
	is      => 'ro',
	isa     => 'ArrayRef[IFS::Decoder::Solution::Symbol::Portal]',
	lazy    => 1,
	builder => '_build_portals',
);
 
sub _build_portals {
	my $self = shift;

	my $portals = [];
	my $last;
	for my $p ( 0 .. $self->max_index ){
		my $portal = IFS::Decoder::Solution::Symbol::Portal->new();
		if ($last) {
			$portal->previous($last);
			$last->next($portal);
		}
		$last = $portal;
		$portals->[$p] = $portal;
	}
	return $portals;
}

sub add {
	my $self = shift;
	my ($pos, $submission) = @_;
	$pos--; # usres start with 1, arrays starrt with 0
	$self->portals->[$pos]->add($submission);
}

sub delete_submission {
	my $self = shift;
	my ($pos, $index) = @_;
	$pos--; # usres start with 1, arrays starrt with 0
	$index--;
	$self->portals->[$pos]->delete_index($index);
}

sub max_index {
	my $self = shift;
	return $self->portal_count - 1;
}

sub structure {
	my $self = shift;
	return $self->structure_header . "\n" . $self->structure_body;
}

sub structure_header {
	my $self = shift;
	return join '', $self->numbers->@[0 .. $self->max_index];
}

sub structure_body {
	my $self = shift;

	if ( $self->is_complete ) {
		my @f = qw(E R);
		return join '', map { $self->square->{ 'done' . $f[rand @f] } } $self->portals->@*;
	}
	else {
		return join '', map { $_->structure_char } $self->portals->@*;
	}
}

sub has_submissions {
	my $self = shift;
	return any { $_->has_submissions } $self->portals->@*;
}

sub is_complete {
	my $self = shift;
	return all { $_->has_submissions } $self->portals->@*;
}

sub iitc_data {
	my $self      = shift;
	my @iitc_data = ();
	my $poly      = 1;
	my $current_poly;
	for my $portal ( $self->portals->@* ) {
		next unless $portal->has_submissions;
		push @iitc_data, $portal->marker( $portal->is_first ? $self->color_gradient->{ $poly++ } : $self->default_color );
		if ( $portal->has_neighbour ) {
			if ( $portal->is_first ) {
				$current_poly = {
					color   => $self->poly_color,
					latLngs => [],
					type    => 'polyline',
				};
				push @iitc_data, $current_poly;
			}
			push $current_poly->{latLngs}->@*, $portal->point;
		}
	}
	return \@iitc_data;
}

sub iitc_json {
	my $self = shift;
	return encode_json( $self->iitc_data );
}

sub links {
	my $self      = shift;
	my @links = ();
	for my $portal ( $self->portals->@* ) {
		next unless $portal->has_submissions && $portal->has_next;
		push @links, [$portal->point->{lat}, $portal->point->{lng}, $portal->next->point->{lat}, $portal->next->point->{lng}];
	}
	return \@links;
}

sub intel_link {
	my $self = shift;
	return '' unless $self->has_submissions;
	my $links = $self->links;
	return '' unless @$links;
	return
		sprintf( 'https://intel.ingress.com/?ll=%s,%s&z=16&pls=', $links->[0][0],$links->[0][1] )
		. join( '_', map { join ',', $_->@* } $links->@* );
}

# https://intel.ingress.com/?ll=48.206085,16.375315&z=16&pls=
# 48.199996,16.369424,48.212021,16.368891
# 48.212021,16.368891,48.211888,16.378676
# 48.211888,16.378676,48.206793,16.378702
# 48.206793,16.378702,48.206852,16.368848
# 48.206852,16.368848,48.20047,16.379501

42;

