#!/usr/bin/perl
use 5.030;

package IFS::Decoder::Solution;
use Moose;
use Data::Dumper;
use File::Slurper qw(write_binary read_binary);
use IFS::Decoder::Solution::Symbol;


has 'header'   => ( is => 'rw', isa => 'Any' );
has 'solution' => ( is => 'rw', isa => 'Str' );

has 'symbols' => (
	traits  => ['Array'],
	is      => 'rw',
	isa     => 'ArrayRef[IFS::Decoder::Solution::Symbol]',
	default => sub { [] },
	handles => {
		add           => 'push',
		symbols_count => 'count',
	},
);

sub persist {
	my $self = shift;
	my ($filename) = @_;
	my $d = Data::Dumper->new([$self], [qw(foo )]);
	$d->Purity(1)->Sortkeys(1); #->Terse(1)->Deepcopy(1);
	write_binary($filename, $d->Dump);
}

sub load {
	my $self = shift;
	my ($filename) = @_;
	my $foo;
	eval read_binary($filename);
	return $foo;
}


sub init {
	my $self = shift;
	my ($symbol_list) = @_;
	$self->symbols( [] );
	for my $symbol_params (@$symbol_list) {
		$self->add( IFS::Decoder::Solution::Symbol->new($symbol_params) );
	}
}

sub symbol {
	my $self = shift;
	my ($symbol_number) = @_;
	$symbol_number--;
	return $self->symbols->[$symbol_number];
}

sub solution_string {
	my $self = shift;

	return $self->_symbol_iterator(
		sub {
			my $symbol = shift;
			return $symbol->solution_or_blank;
		},
		"",
	);
}

sub structure_string {
	my $self = shift;

	return $self->_symbol_iterator(
		sub {
			my $symbol = shift;
			return $symbol->structure_body;
		},
		"\n",
	);
}

sub progress {
	my $self   = shift;
	my $return = "Solution: " . $self->solution_string;

	return $self->_symbol_iterator(
		sub {
			my ($symbol, $i) = @_;

			my @symbol_text = ();
			push @symbol_text, join ' ', "Symbol $i:", $symbol->portal_count, 'portals', $symbol->type // '';
			push @symbol_text, join ' ', $symbol->solution_or_blank, $symbol->solution_note;
			push @symbol_text, join ' ', $symbol->structure;
			push @symbol_text, "/show_detail_$i";
			# push @symbol_text, join ' ', 'IITC Drawing:', $symbol->iitc_json;
			# push @symbol_text, join ' ', 'Stock Intel:',  $symbol->intel_link;
			return join "\n", @symbol_text;

		},
		"\n\n",
	);
}

sub detail {
	my $self = shift;
	my ($symbol_number) = @_;
	my $index = $symbol_number - 1;
	return "Symbol: $symbol_number ".$self->symbols->[$index]->detail;
}

sub solve {
	my $self = shift;
	my ($symbol_number, $solution, $solution_note) = @_;
	my $index = $symbol_number - 1;
	$self->symbols->[$index]->solve($solution, $solution_note);
	return "Solution '$solution' recoded for Symbol: $symbol_number";
}

sub _symbol_iterator {
	my $self = shift;
	my ( $symbol_renderer, $join_string ) = @_;
	my @return = ();
	my $i = 1;
	for my $symbol ( $self->symbols->@* ) {
		push @return, $symbol_renderer->( $symbol, $i++ );
	}
	return join $join_string, @return;
}
42;

