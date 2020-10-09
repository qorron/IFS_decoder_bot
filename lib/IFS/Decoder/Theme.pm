#!/usr/bin/perl

use 5.030;
package IFS::Decoder::Theme;
use Moose::Role;

has 'numbers' => (
	is      => 'ro',
	isa     => 'ArrayRef[Str]',
	default => sub { [qw(1️⃣ 2️⃣ 3️⃣ 4️⃣ 5️⃣ 6️⃣ 7️⃣ 8️⃣ 9️⃣ 🔟),] },
);

has 'square' => (
	is      => 'ro',
	isa     => 'HashRef[Str]',
	default => sub {
		{   none   => '❌',
			single => '🟧',
			multi  => '🟨',
			doneE  => '🟩',
			doneR  => '🟦',
		}
	},
);

has 'color_gradient' => (
	is      => 'ro',
	isa     => 'HashRef[Str]',
	default => sub {
		{   1 => '#57D600',
			2 => '#CFD200',
			3 => '#CE5900',
			4 => '#CA001D',
			5 => '#C60090',
			6 => '#8700C2',
			7 => '#1500BF',
		}
	},
);

has 'default_color' => (
	is      => 'ro',
	isa     => 'Str',
	default => '#aaaaaa',
);

has 'poly_colors' => (
	is      => 'ro',
	isa     => 'HashRef[Str]',
	default => sub {
		{   letter  => '#3476d1',
			number  => '#43d921',
			keyword => '#d14a21',
			glyph   => '#d14a21',
			default => '#a24ac3',
		}
	},
);

sub poly_color {
	my $self = shift;
	return unless $self->meta->has_method('type');
	return $self->poly_colors->{ $self->type } if exists $self->poly_colors->{ $self->type };
	return $self->poly_colors->{default};
}

42;

