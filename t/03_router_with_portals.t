#!/usr/bin/perl
use strict;
use warnings;
use 5.030;
use Data::Dumper;
use Test::More tests => 17;
use Encode;
use JSON;   
use Test::JSON;
    
use lib qw(../lib lib);
use Telegram::Message;
use Telegram::Reply;
# use Telegram::Target;
# use Telegram::Target::SimpleCommand;
# use Telegram::Target::OneArgCommand;
# use Telegram::Target::Pattern;

use IFS::Decoder::Bot;

my $bot = new_ok( 'IFS::Decoder::Bot', [], 'new bot object' );


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
	'text' => "/init\nheader passcode: xxx##keyword###xx",
};
my $message_raw_3 = {
	%$message_raw_1,
	'text' => <<INIT,
/init
header passcode: xxx##keyword###xx
6 letter
8 letter
6 letter
5
6
5 
7 
8
5
7
5 glyph
8 number
8 number

8 number
6 letter
5 letter

INIT
};
my $message_raw_4 = {
	%$message_raw_1,
	'text' => '1-1 3-2 4-2 historisches Marterl https://intel.ingress.com/intel?ll=48.198995,16.386526&z=17&pll=48.198995,16.386526',
};
my $message_raw_5 = {
	%$message_raw_1,
	'text' => '1-1 https://intel.ingress.com/intel?ll=48.198995,16.386526&z=17&pll=48.198900,16.386500',
};
my $message_raw_6 = {
	%$message_raw_1,
	'text' => '/summary',
};
my $message_raw_7 = {
	%$message_raw_1,
	'text' => '/show_detail_1',
};
my $message_7 = Telegram::Message->new($message_raw_7);

my $message_raw_8 = {
	%$message_raw_1,
	'text' => '/solve 1 r',
};
my $message_raw_9 = {
	%$message_raw_1,
	'text' => '/solve 1 R ',
};
my $message_raw_10 = {
	%$message_raw_1,
	'text' => "/solve 1 R I'm sure",
};
my $message_raw_11 = {
	%$message_raw_1,
	'text' => '/save_xxx',
};
my $message_raw_12 = {
	%$message_raw_1,
	'text' => '/load_xxx',
};
my $message_raw_13 = {
	%$message_raw_1,
	'text' => '/undo 1-1',
};
my $have;

is_deeply( $have = $bot->router->route(Telegram::Message->new($message_raw_1)), [] , 'unknown command' ) || diag explain $have;
is_deeply(
	$have = $bot->router->route( Telegram::Message->new($message_raw_2) ),
	[   bless(
			{   'chat_id'    => -402559723,
				'parse_mode' => 'HTML',
				'text'       => 'ok, initialized solution with 0 symbols, header: passcode: xxx##keyword###xx'
			},
			'Telegram::Reply'
		)
	],
	'init with no portals'
) || diag explain $have;
is_deeply(
	$have = $bot->router->route( Telegram::Message->new($message_raw_3) ),
	[   bless(
			{   'chat_id'    => -402559723,
				'parse_mode' => 'HTML',
				'text'       => 'ok, initialized solution with 16 symbols, header: passcode: xxx##keyword###xx'
			},
			'Telegram::Reply'
		)
	],
	'init with 16 symbols'
) || diag explain $have;

is_deeply(
	$have = $bot->router->route( Telegram::Message->new($message_raw_4) ),
	[   bless(
			{   'chat_id'    => -402559723,
				'parse_mode' => 'HTML',
				'text'       => 'pictures: 1-1 3-2 4-2
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
🟧❌❌❌❌❌
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
❌🟧❌❌❌❌
1️⃣2️⃣3️⃣4️⃣5️⃣
❌🟧❌❌❌
'
			},
			'Telegram::Reply'
		)
	],
	'add a submission to 3 portals'
) || diag explain $have;

is_deeply(
	$have = $bot->router->route( Telegram::Message->new($message_raw_5) ),
	[   bless(
			{   'chat_id'    => -402559723,
				'parse_mode' => 'HTML',
				'text'       => 'pictures: 1-1
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
🟧❌❌❌❌❌
'
			},
			'Telegram::Reply'
		)
	],
	'add a solution to a portal already having a solution overwriting the older one'
) || diag explain $have;


is_deeply(
	$have = $bot->router->route( Telegram::Message->new($message_raw_6) ),
	[   bless(
			{   'chat_id'    => -402559723,
				'parse_mode' => 'HTML',
				'text'       => 'Symbol 1: 6 portals letter
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
🟧❌❌❌❌❌
/show_detail_1

Symbol 2: 8 portals letter
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣
❌❌❌❌❌❌❌❌
/show_detail_2

Symbol 3: 6 portals letter
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
❌🟧❌❌❌❌
/show_detail_3

Symbol 4: 5 portals 
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣
❌🟧❌❌❌
/show_detail_4

Symbol 5: 6 portals 
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
❌❌❌❌❌❌
/show_detail_5

Symbol 6: 5 portals 
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣
❌❌❌❌❌
/show_detail_6

Symbol 7: 7 portals 
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣
❌❌❌❌❌❌❌
/show_detail_7

Symbol 8: 8 portals 
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣
❌❌❌❌❌❌❌❌
/show_detail_8

Symbol 9: 5 portals 
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣
❌❌❌❌❌
/show_detail_9

Symbol 10: 7 portals 
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣
❌❌❌❌❌❌❌
/show_detail_10

Symbol 11: 5 portals glyph
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣
❌❌❌❌❌
/show_detail_11

Symbol 12: 8 portals number
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣
❌❌❌❌❌❌❌❌
/show_detail_12

Symbol 13: 8 portals number
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣
❌❌❌❌❌❌❌❌
/show_detail_13

Symbol 14: 8 portals number
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣8️⃣
❌❌❌❌❌❌❌❌
/show_detail_14

Symbol 15: 6 portals letter
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
❌❌❌❌❌❌
/show_detail_15

Symbol 16: 5 portals letter
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣
❌❌❌❌❌
/show_detail_16'
			},
			'Telegram::Reply'
		)
	],
	'summary'
) || diag explain $have;


is_deeply(
	$have = $bot->router->route( $message_7 ),
	[   bless(
			{   'chat_id'    => -402559723,
				'parse_mode' => 'HTML',
				'text'       => 'Symbol: 1 letter
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
🟧❌❌❌❌❌
IITC Drawing:
<code>[{"color":"#57D600","latLng":{"lat":"48.198900","lng":"16.386500"},"type":"marker"}]</code>
'
			},
			'Telegram::Reply'
		)
	],
	'detail'
) || diag explain $have;

is_deeply(
    $have = $bot->router->route( Telegram::Message->new($message_raw_8) ),
    [   bless(
            {   'chat_id'    => -402559723,
                'parse_mode' => 'HTML',
                'text'       => "Solution 'r' recoded for Symbol: 1",
            },
            'Telegram::Reply'
        )   
    ],  
    'simple solve'
) || diag explain $have;

is_deeply(
    $have = $bot->router->route( $message_7 ),
    [   bless(
            {   'chat_id'    => -402559723,
                'parse_mode' => 'HTML',
                'text'       => 'Symbol: 1 letter
Solution: \'r\'
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
🟧❌❌❌❌❌
IITC Drawing:
<code>[{"color":"#57D600","latLng":{"lat":"48.198900","lng":"16.386500"},"type":"marker"}]</code>
'
            },
            'Telegram::Reply'
        )   
    ],  
    'detail'
) || diag explain $have;

is_deeply(
    $have = $bot->router->route( Telegram::Message->new($message_raw_9) ),
    [   bless(
            {   'chat_id'    => -402559723,
                'parse_mode' => 'HTML',
                'text'       => "Solution 'R' recoded for Symbol: 1",
            },
            'Telegram::Reply'
        )   
    ],  
    'solve with space at end'
) || diag explain $have;

is_deeply(
    $have = $bot->router->route( $message_7 ),
    [   bless(
            {   'chat_id'    => -402559723,
                'parse_mode' => 'HTML',
                'text'       => 'Symbol: 1 letter
Solution: \'R\'
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
🟧❌❌❌❌❌
IITC Drawing:
<code>[{"color":"#57D600","latLng":{"lat":"48.198900","lng":"16.386500"},"type":"marker"}]</code>
'
            },
            'Telegram::Reply'
        )   
    ],  
    'detail'
) || diag explain $have;


is_deeply(
    $have = $bot->router->route( Telegram::Message->new($message_raw_10) ),
    [   bless(
            {   'chat_id'    => -402559723,
                'parse_mode' => 'HTML',
                'text'       => "Solution 'R' recoded for Symbol: 1",
            },
            'Telegram::Reply'
        )   
    ],  
    'solve with note'
) || diag explain $have;

is_deeply(
    $have = $bot->router->route( $message_7 ),
    [   bless(
            {   'chat_id'    => -402559723,
                'parse_mode' => 'HTML',
                'text'       => 'Symbol: 1 letter
Solution: \'R\' I\'m sure
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
🟧❌❌❌❌❌
IITC Drawing:
<code>[{"color":"#57D600","latLng":{"lat":"48.198900","lng":"16.386500"},"type":"marker"}]</code>
'
            },
            'Telegram::Reply'
        )   
    ],  
    'detail'
) || diag explain $have;

$bot->_store;
$bot->_load;
is_deeply(
    $have = $bot->router->route( $message_7 ),
    [   bless(
            {   'chat_id'    => -402559723,
                'parse_mode' => 'HTML',
                'text'       => 'Symbol: 1 letter
Solution: \'R\' I\'m sure
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
🟧❌❌❌❌❌
IITC Drawing:
<code>[{"color":"#57D600","latLng":{"lat":"48.198900","lng":"16.386500"},"type":"marker"}]</code>
'
            },
            'Telegram::Reply'
        )   
    ],  
    'detail after store/load'
) || diag explain $have;


is_deeply(
    $have = $bot->router->route( Telegram::Message->new($message_raw_11) ),
    [   bless(
            {   'chat_id'    => -402559723,
                'parse_mode' => 'HTML',
                'text'       => 'stored as xxx'
            },
            'Telegram::Reply'
        )   
    ],  
    'manual store'
) || diag explain $have;

is_deeply(
    $have = $bot->router->route( Telegram::Message->new($message_raw_12) ),
    [   bless(
            {   'chat_id'    => -402559723,
                'parse_mode' => 'HTML',
                'text'       => 'loaded xxx'
            },
            'Telegram::Reply'
        )   
    ],  
    'manual store'
) || diag explain $have;

# is_deeply(
#     $have = $bot->router->route( Telegram::Message->new($message_raw_13) ),
#     [   bless(
#             {   'chat_id'    => -402559723,
#                 'parse_mode' => 'HTML',
#                 'text'       => 'loaded xxx'
#             },
#             'Telegram::Reply'
#         )   
#     ],  
#     'undo portal'
# ) || diag explain $have;
#$bot->_store;
