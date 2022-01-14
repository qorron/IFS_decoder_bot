#!/usr/bin/perl

package IFS::Decoder::Bot;
use Moose;
use IFS::Decoder::Solution;
use IFS::Decoder::Submitter;
use IFS::Decoder::Solution::Symbol::Portal::Submission;
use Telegram::Chat;
use Telegram::User;
use Telegram::Message;
use Telegram::Reply;
use Telegram::Router;
use Telegram::Target::Pattern;
use Telegram::Target::OneArgCommand;
use Telegram::Target::SimpleCommand;
use Data::Dumper;
use JSON;

# summary - shows a summary of all symbols

has 'bot_masters' => (
	traits  => ['Array'],
	is      => 'rw',
	isa     => 'ArrayRef[Int]',
	handles => { add_master => 'push', },
);

has 'router' => (
	is      => 'rw',
	isa     => 'Telegram::Router',
	lazy    => 1,
	builder => '_build_router',
);

has 'bot_id' => (
	is       => 'rw',
	isa      => 'Str',
	required => 1,
	default  => 'test',
);
has 'persistance_file_pattern' => (
	is      => 'rw',
	isa     => 'Str',
	lazy    => 1,
	builder => '_build_persistance_file_pattern',
);
has 'file_serial' => (
	traits   => ['Counter'],
	is       => 'rw',
	isa      => 'Int',
	required => 1,
	default  => 0,
	handles  => { next_serial => 'inc', },
);
has 'solution' => (
	is      => 'rw',
	isa     => 'IFS::Decoder::Solution',
	lazy    => 1,
	builder => '_build_solution',
);
#IFS::Decoder::Solution->new( header => 'keyword: xxx##keyword###xx' );
has '_new_portal_pattern' => (
	is      => 'ro',
	isa     => 'RegexpRef',
	default => sub { qr/^
			(?<pictures>
				(?:
					\d+
					[-.]+
					\d+
					\S*
					\s+
				)+
			)
			(?:
				(?<notes>
					.+?
				)
				\s+
			)?
			(?<portal>
				\S+
				pll=(?<lat>
						\d+(?:\.\d+)?
					)
					,
					(?<lng>
						\d+(?:\.\d+)?
					)
			)/x } ,
);

has '_init_pattern' => (
	is      => 'ro',
	isa     => 'RegexpRef',
	default => sub { qr(^/init\nheader)i },
);
has '_solve_pattern' => (
	is      => 'ro',
	isa     => 'RegexpRef',
	default => sub { qr(^/solve (\d+)\s+(\w+)(?:\s+(\S.*)|\s*)$)i },
);
has '_undo_portal_pattern' => (
	is      => 'ro',
	isa     => 'RegexpRef',
	default => sub { qr(^/undo (\d+)[-.](\d+)\s*$)i },
);

sub _build_persistance_file_pattern {
	my $self = shift;
	return 'solution_' . $self->bot_id . '_%s.pl';
}
sub filename {
	my $self = shift;
	my ($name ) = @_;
	$name //= $self->next_serial;
	
	return sprintf($self->persistance_file_pattern, $name);

}

sub _build_solution {
	my $self = shift;
	return IFS::Decoder::Solution->new( header => 'empty header' );
}

sub _build_router {
	my $self   = shift;
	my $router = Telegram::Router->new();
	$router->add_target(
		Telegram::Target::Pattern->new(
			pattern => $self->_new_portal_pattern,
			handler => sub { $self->_handle_new_portal(@_) },
		)
	);
# 	$router->add_target(
# 		Telegram::Target::Pattern->new(
# 			pattern => $self->_undo_portal_pattern,
# 			handler => sub { $self->_handle_undo_portal(@_) },
# 		)
# 	);
	$router->add_target(
		Telegram::Target::Pattern->new(
			pattern => $self->_init_pattern,
			handler => sub { $self->_handle_init(@_) },
		)
	);
	$router->add_target(
		Telegram::Target::Pattern->new(
			pattern => $self->_solve_pattern,
			handler => sub { $self->solution->solve($_[0]->@*) },
		)
	);
	$router->add_target(
		Telegram::Target::SimpleCommand->new(
			command => 'summary',
			handler => sub { $self->solution->progress },
		)
	);
	$router->add_target(
		Telegram::Target::OneArgCommand->new(
			command => 'show_detail_',
			handler => sub { $self->solution->detail( $_[1] ) },
		)
	);
	$router->add_target(
		Telegram::Target::OneArgCommand->new(
			command => 'save_',
			handler => sub {
				if ( $_[1] =~ /^\w+$/ ) {
					$self->_store( $_[1] );
					return "stored as $_[1]";
				}
			},
		)
	);
	$router->add_target(
		Telegram::Target::OneArgCommand->new(
			command => 'load_',
			handler => sub {
				if ( $_[1] =~ /^\w+$/ && $self->_has_file( $_[1] ) ) {
					$self->_load( $_[1] );
					return "loaded $_[1]";
				}
			},
		)
	);
	return $router;
}

sub _handle_init {
	my ( $self, $c, $m ) = @_;

	my $header;
	my $symbol_args_list = [];
	$header = $1 if $m->text =~ /header (.*)$/mi;
	for my $line ( split /\n/, $m->text ) {
		if ( $line =~ /^(\d+)\s*(\S.*)?$/ ) {
			my $count = $1;
			my $type  = $2;
			push @$symbol_args_list, { portal_count => $count };
			$symbol_args_list->[-1]{type} = $type if $type;
		}
		else {
			# warn "ignore line: $line";
		}
	}

	$self->solution->header($header);
	$self->solution->init($symbol_args_list);
	return "ok, initialized solution with ".$self->solution->symbols_count." symbols, header: ".$self->solution->header;
}

sub _handle_new_portal {
	my ( $self, $c, $m ) = @_;
	$c->{pictures} =~ s/\s+$//;
	my @pics       = split /\s+/, $c->{pictures};
	my $r          = "pictures: " . join( ' ', @pics )."\n";
	my $submission = IFS::Decoder::Solution::Symbol::Portal::Submission->new(
		'note'      => $c->{notes} // '',
		'submitter' => $m->from,
		'lat'       => $c->{lat},
		'lng'       => $c->{lng},
	);
	for my $pic (@pics) {
		my ( $symbol_number, $pic_number ) = split /\W/, $pic;
		$self->solution->symbol($symbol_number)->add( $pic_number, $submission );
		$r .= $self->solution->symbol($symbol_number)->structure."\n";
	}
	#return Telegram::Reply->to_message($m)->text($r);
	$self->_store unless $self->bot_id eq 'test';
	return $r;
}

sub _handle_undo_portal {
	my ( $self, $c, $m ) = @_;
	my ($symbol_number, $pic_number) = $c->@*;
	return;


	$c->{pictures} =~ s/\s+$//;
	my @pics       = split /\s+/, $c->{pictures};
	my $r          = "pictures: " . join( ' ', @pics )."\n";
	my $submission = IFS::Decoder::Solution::Symbol::Portal::Submission->new(
		'note'      => $c->{notes} // '',
		'submitter' => $m->from,
		'lat'       => $c->{lat},
		'lng'       => $c->{lng},
	);
	for my $pic (@pics) {
		my ( $symbol_number, $pic_number ) = split /\W/, $pic;
		$self->solution->symbol($symbol_number)->delete_submission( $pic_number );
		$r .= $self->solution->symbol($symbol_number)->structure."\n";
	}
	#return Telegram::Reply->to_message($m)->text($r);
	$self->_store unless $self->bot_id eq 'test';
	return $r;
}
sub _store {
	my $self = shift;
	my ($name ) = @_;
	my $filename = $self->filename($name);
	
	$self->solution->persist( $filename);
	unlink $self->filename('last');
	symlink($filename,$self->filename('last'));
}

sub _load {
	my $self = shift;
	my ($name ) = @_;
	$name //= 'last';
	$self->solution( IFS::Decoder::Solution->load( $self->filename($name)) );
}

sub load_last {
	my $self = shift;
	$self->_load();
}

sub has_last {
	my $self = shift;
	return $self->_has_file('last');
}

sub _has_file {
	my $self = shift;
	my ($name) = @_;
	return -e $self->filename($name);
}


sub _is_from_master {
}



42;

