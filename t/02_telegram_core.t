#!/usr/bin/perl
use strict;
use warnings;
use 5.030;
use Data::Dumper;
use Test::More tests => 15;
use Encode;
use JSON;   
use Test::JSON;
    
use lib qw(../lib lib);
use Telegram::Message;
use Telegram::Router;
use Telegram::Target;
use Telegram::Target::SimpleCommand;
use Telegram::Target::OneArgCommand;
use Telegram::Target::Pattern;

my $message_raw_1 = {
	'text' => '/hello',
	'date' => 1602604979,
	'from' => {
		'id'            => 204066609,
		'username'      => 'youAreDoingItWrong',
		'is_bot'        => bless( do { \( my $o = 0 ) }, 'JSON::PP::Boolean' ),
		'first_name'    => "\x{1d69a}\x{1d69e}\x{1d68a}\x{1d69d}\x{1d69d}\x{1d69b}\x{1d698}",
		'language_code' => 'en'
	},
	'message_id' => 250,
	'chat'       => {
		'title'                          => 'IFS Decoder test',
		'all_members_are_administrators' => bless( do { \( my $o = 1 ) }, 'JSON::PP::Boolean' ),
		'type'                           => 'group',
		'id'                             => -402559723
	}
};
my $message_raw_2 = {
	%$message_raw_1,
	'text' => '/usero',
};
my $message_raw_3 = {
	%$message_raw_1,
	'text' => '/double733',
};
my $message_raw_4 = {
	%$message_raw_1,
	'text' => '1-1 3-2 4-2 historisches Marterl https://intel.ingress.com/intel?ll=48.198995,16.386526&z=17&pll=48.198995,16.386526',
};
my $message_raw_5 = {
	%$message_raw_1,
	'text' => '1-1 https://intel.ingress.com/intel?ll=48.198995,16.386526&z=17&pll=48.198995,16.386526',
};

my $message_1 = new_ok( 'Telegram::Message', [%$message_raw_1], 'new message object' );
my $message_2 = new_ok( 'Telegram::Message', [%$message_raw_2], 'new message object' );
my $message_3 = new_ok( 'Telegram::Message', [%$message_raw_3], 'new message object' );
my $message_4 = new_ok( 'Telegram::Message', [%$message_raw_4], 'new message object' );
my $message_5 = new_ok( 'Telegram::Message', [%$message_raw_5], 'new message object' );
my $router    = new_ok( 'Telegram::Router',  [],                'new telegram router' );
my $target_1 = new_ok( 'Telegram::Target::SimpleCommand', [command => 'hello', handler => sub {'world'}], 'new target' );
my $target_2 = new_ok(
	'Telegram::Target::SimpleCommand',
	[   command => 'user',
		handler => sub { my ( $c, $m ) = @_; 'hello ' . $m->from->username . ' command: /' . $c }
	],
	'new target'
);
my $target_3 = new_ok(
	'Telegram::Target::OneArgCommand',
	[   command => 'double',
		handler => sub { my ( $c, $arg, $m ) = @_; 'argument ' . $arg . ' times 2 is: ' . ( $arg * 2 ) }
	],
	'new target'
);
my $target_4 = new_ok(
	'Telegram::Target::Pattern',
	[   pattern => qr/^
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
			)/x ,
		handler => sub {
			my ( $c, $m ) = @_;
			$c->{pictures} =~ s/\s+$//;
			my @pics = split /\ş+/, $c->{pictures};
			my $r = "pictures: ".join(' ', @pics);
			$r .= "\nnotes: $c->{notes}" if $c->{notes};
			$r .= "\nlat: $c->{lat}\nlng: $c->{lng}";
			return $r;
			}
	],
	'new target'
);

$router->add_target($target_1);
$router->add_target($target_2);
$router->add_target($target_3);
$router->add_target($target_4);
is( $router->route($message_1)->[0]->text, 'world', 'simple command' );
is( $router->route($message_2)->[0]->text, 'hello youAreDoingItWrong command: /user', 'simple command, reacts to message' );
is( $router->route($message_3)->[0]->text, 'argument 733 times 2 is: 1466', 'command with one arg' );
is( $router->route($message_4)->[0]->text, "pictures: 1-1 3-2 4-2\nnotes: historisches Marterl\nlat: 48.198995\nlng: 16.386526", 'pattern' );
is( $router->route($message_5)->[0]->text, "pictures: 1-1\nlat: 48.198995\nlng: 16.386526", 'pattern' );
