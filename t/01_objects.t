#!/usr/bin/perl
use strict;
use warnings;
use 5.030;
use Data::Dumper;
use Test::More tests => 53;
use Encode;
use JSON;
use Test::JSON;

use lib qw(../lib lib);

use IFS::Decoder::Submitter;
use IFS::Decoder::Solution;
use IFS::Decoder::Solution::Symbol;
use IFS::Decoder::Solution::Symbol::Portal;
use IFS::Decoder::Solution::Symbol::Portal::Submission;

my $points = [
	{ "lat" => "48.199996", "lng" => "16.369424" },
	{ "lng" => "16.368891", "lat" => "48.212021" },
	{ "lng" => "16.378676", "lat" => "48.211888" },
	{ "lng" => "16.378702", "lat" => "48.206793" },
	{ "lat" => "48.206852", "lng" => "16.368848" },
	{ "lng" => "16.379501", "lat" => "48.20047" }
];

my $submitter_1 = new_ok(
	'IFS::Decoder::Submitter' => [
		'language_code' => 'en',
		'id'            => 204066609,
		'is_bot'        => bless( do { \( my $o = 0 ) }, 'JSON::PP::Boolean' ),
		'first_name'    => "\x{1d69a}\x{1d69e}\x{1d68a}\x{1d69d}\x{1d69d}\x{1d69b}\x{1d698}",
		'username'      => 'youAreDoingItWrong'
	],
	encode( 'utf-8', "generate Submitter \x{1d69a}\x{1d69e}\x{1d68a}\x{1d69d}\x{1d69d}\x{1d69b}\x{1d698}" )
);

my $submitter_2 = new_ok(
	'IFS::Decoder::Submitter' => [
		'id'         => 124501718,
		'last_name'  => 'V.',
		'username'   => 'Polarhare',
		'first_name' => 'Kathrin',
		'is_bot'     => bless( do { \( my $o = 0 ) }, 'JSON::PP::Boolean' )
	],
	'generate Submitter Polarhare'
);

my $submission_1 = new_ok(
	'IFS::Decoder::Solution::Symbol::Portal::Submission' => [
		'submitter' => $submitter_1,
		'lat'       => 48.19999,
		'lng'       => 16.36942,
	],
	'generate Submission 1'
);

my $submission_2 = new_ok(
	'IFS::Decoder::Solution::Symbol::Portal::Submission' => [
		'note'      => 'Marterl zum Heiligen Hasen',
		'submitter' => $submitter_2,
		'lat'       => 48.199996,
		'lng'       => 16.369424,
	],
	'generate Submission 2'
);

is_deeply( $submission_1->point, { lat => 48.19999, lng => 16.36942 }, 'get the point back correctly' );

my $portal_1 = new_ok( 'IFS::Decoder::Solution::Symbol::Portal' => [], 'generate a portal' );

ok( !$portal_1->has_submissions, 'has no submissions' );
is( $portal_1->structure_char, '❌', 'get a ❌ for an empty portal' );
$portal_1->add($submission_1);
is_deeply( $portal_1->point, { lat => 48.19999, lng => 16.36942 }, 'get the single point back correctly' );
is( $portal_1->structure_char, '🟧', 'get a 🟧 for a loner' );
ok( $portal_1->has_submissions, 'has submissions' );
$portal_1->add($submission_2);
is_deeply( $portal_1->point, { lat => 48.199996, lng => 16.369424 }, 'get the last submitted point back correctly' );

my $symbol_1 = new_ok(
	'IFS::Decoder::Solution::Symbol' => [
		portal_count => 6,
		type         => 'letter'
	],
	'generate new symbol'
);

my $iitc_data;
my $iitc_json;
my $intel_link;
is( $symbol_1->max_index,        5,                                            'max_index' );
is( $symbol_1->structure_header, '1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣', 'structure header' );
is( $symbol_1->structure_body,   '❌❌❌❌❌❌',                         'structure body: empty' );
is_deeply( $iitc_data = $symbol_1->iitc_data, ref_data('empty'), 'iitc data ok' )                or diag( Dumper $iitc_data);
is_json( $iitc_json   = $symbol_1->iitc_json, encode_json( ref_data('empty') ), 'iitc json ok' ) or diag("json: $iitc_json");
is( $intel_link = $symbol_1->intel_link, ref_intel('empty'), 'intel link ok' ) or diag("intel_link: $intel_link");
$symbol_1->add( 1, $submission_1 );
is( $symbol_1->structure_body, '🟧❌❌❌❌❌', 'structure body: first set' );
$symbol_1->add( 1, $submission_2 );
is( $symbol_1->structure_body, '🟧❌❌❌❌❌', 'structure body: first set again' );
is_deeply( $iitc_data = $symbol_1->iitc_data, ref_data('loner'), 'iitc data ok' )                or diag( Dumper $iitc_data);
is_json( $iitc_json   = $symbol_1->iitc_json, encode_json( ref_data('loner') ), 'iitc json ok' ) or diag("json: $iitc_json");
is( $intel_link = $symbol_1->intel_link, ref_intel('loner'), 'intel link ok' ) or diag("intel_link: $intel_link");

my @submissions = ('nothing');
for my $point (@$points) {
	push @submissions, IFS::Decoder::Solution::Symbol::Portal::Submission->new( submitter => $submitter_1, %$point );
}

$symbol_1->add( 3, $submissions[3] );
is( $symbol_1->structure_body, '🟧❌🟧❌❌❌', 'structure body: two loners' );
is_deeply( $iitc_data = $symbol_1->iitc_data, ref_data('two_loners'), 'iitc data ok' )                or diag( Dumper $iitc_data);
is_json( $iitc_json   = $symbol_1->iitc_json, encode_json( ref_data('two_loners') ), 'iitc json ok' ) or diag("json: $iitc_json");
is( $intel_link = $symbol_1->intel_link, ref_intel('two_loners'), 'intel link ok' ) or diag("intel_link: $intel_link");
$symbol_1->add( 4, $submissions[4] );
is( $symbol_1->structure_body, '🟧❌🟨🟨❌❌', 'structure body: loner + couple' );
$symbol_1->add( 5, $submissions[5] );
is( $symbol_1->structure_body, '🟧❌🟨🟨🟨❌', 'structure body: loner + tripple' );
is_deeply( $iitc_data = $symbol_1->iitc_data, ref_data('loner_triplet'), 'iitc data ok' ) or diag( Dumper $iitc_data);
is_json( $iitc_json   = $symbol_1->iitc_json, encode_json( ref_data('loner_triplet') ), 'iitc json ok' )
	or diag("json: $iitc_json");
is( $intel_link = $symbol_1->intel_link, ref_intel('loner_triplet'), 'intel link ok' ) or diag("intel_link: $intel_link");
$symbol_1->add( 2, $submissions[2] );
is( $symbol_1->structure_body, '🟨🟨🟨🟨🟨❌', 'structure body: group of five' );
$symbol_1->delete_submission( 3, 1 );
is( $symbol_1->structure_body, '🟨🟨❌🟨🟨❌', 'structure body: two couples after delete' );
is_deeply( $iitc_data = $symbol_1->iitc_data, ref_data('two_couples'), 'iitc data ok' ) or diag( Dumper $iitc_data);
is_json( $iitc_json = $symbol_1->iitc_json, encode_json( ref_data('two_couples') ), 'iitc json ok' ) or diag("json: $iitc_json");
is( $intel_link = $symbol_1->intel_link, ref_intel('two_couples'), 'intel link ok' ) or diag("intel_link: $intel_link");
$symbol_1->add( 3, $submissions[3] );
$symbol_1->add( 6, $submissions[6] );
like( $symbol_1->structure_body, qr/(?:🟩|🟦){6}/, 'structure body: complete' );
is_deeply( $iitc_data = $symbol_1->iitc_data, ref_data('full'), 'iitc data ok' )                or diag( Dumper $iitc_data);
is_json( $iitc_json   = $symbol_1->iitc_json, encode_json( ref_data('full') ), 'iitc json ok' ) or diag("json: $iitc_json");
is( $intel_link = $symbol_1->intel_link, ref_intel('full'), 'intel link ok' ) or diag("intel_link: $intel_link");
ok(!$symbol_1->has_solution, 'no solution yet');
$symbol_1->solve('R');
ok($symbol_1->has_solution, 'now we have a solution');
$symbol_1->solve('R', "I'm sure");
ok($symbol_1->has_solution, 'we still have a solution');


my $solution = new_ok('IFS::Decoder::Solution' => [header => 'keyword: xxx##keyword###xx' ], 'generate a solution');

my $symbol_2 = new_ok(
	'IFS::Decoder::Solution::Symbol' => [
		portal_count => 5,
		type         => 'number'
	],
	'generate new symbol'
);
my $symbol_3 = new_ok(
	'IFS::Decoder::Solution::Symbol' => [
		portal_count => 7,
		type         => 'glyph'
	],
	'generate new symbol'
);

$solution->add($symbol_1);
$solution->add($symbol_2);
$solution->add($symbol_3);

$symbol_2->add( 3, $submissions[3] );
$symbol_2->add( 4, $submissions[4] );
$symbol_2->add( 5, $submissions[5] );
$symbol_2->add( 1, $submissions[1] );
$symbol_3->add( 5, $submissions[5] );
$symbol_3->add( 6, $submissions[6] );
$symbol_3->add( 2, $submissions[2] );
$symbol_3->add( 1, $submissions[1] );

$symbol_3->solve('x', "maybe");
is ($symbol_3->detail, q!glyph
Solution: 'x' maybe
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣
🟨🟨❌❌🟨🟨❌
IITC Drawing:
<code>[{"color":"#57D600","latLng":{"lat":"48.199996","lng":"16.369424"},"type":"marker"},{"color":"#d14a21","latLngs":[{"lat":"48.199996","lng":"16.369424"},{"lat":"48.212021","lng":"16.368891"}],"type":"polyline"},{"color":"#aaaaaa","latLng":{"lat":"48.212021","lng":"16.368891"},"type":"marker"},{"color":"#CFD200","latLng":{"lat":"48.206852","lng":"16.368848"},"type":"marker"},{"color":"#d14a21","latLngs":[{"lat":"48.206852","lng":"16.368848"},{"lat":"48.20047","lng":"16.379501"}],"type":"polyline"},{"color":"#aaaaaa","latLng":{"lat":"48.20047","lng":"16.379501"},"type":"marker"}]</code>
<a href="https://intel.ingress.com/?ll=48.199996,16.369424&z=16&pls=48.199996,16.369424,48.212021,16.368891_48.206852,16.368848,48.20047,16.379501">Stock Intel Link</a>
!, 'symbol detail');

#diag( $solution->solution_string );
is( $solution->solution_string, 'R_x', 'present solution' );
#diag( $solution->structure_string );
like( $solution->structure_string, qr"(?:🟩|🟦){6}\n🟧❌🟨🟨🟨\n🟨🟨❌❌🟨🟨❌",
	'present structure' );
# diag($solution->progress);
like( $solution->progress, qr"Symbol 1: 6 portals letter
R I'm sure
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣
(?:🟩|🟦){6}
/show_detail_1

Symbol 2: 5 portals number
_ 
1️⃣2️⃣3️⃣4️⃣5️⃣
🟧❌🟨🟨🟨
/show_detail_2

Symbol 3: 7 portals glyph
x maybe
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣
🟨🟨❌❌🟨🟨❌
/show_detail_3",
	'present summary' );

# like( $solution->progress, qr"Symbol 1: 6 portals letter\nR I'm sure\n1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣\n[🟩🟦]{6}\n/show_detail_1\n\nSymbol 2: 5 portals number\n_ \n1️⃣2️⃣3️⃣4️⃣5️⃣\n🟧❌🟨🟨🟨\n/show_detail_2\n\nSymbol 3: 7 portals glyph\n_ \n1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣\n🟨🟨❌❌🟨🟨❌\n/show_detail_3",
#     'present summary' );



is ($solution->detail(3), q!Symbol: 3 glyph
Solution: 'x' maybe
1️⃣2️⃣3️⃣4️⃣5️⃣6️⃣7️⃣
🟨🟨❌❌🟨🟨❌
IITC Drawing:
<code>[{"color":"#57D600","latLng":{"lat":"48.199996","lng":"16.369424"},"type":"marker"},{"color":"#d14a21","latLngs":[{"lat":"48.199996","lng":"16.369424"},{"lat":"48.212021","lng":"16.368891"}],"type":"polyline"},{"color":"#aaaaaa","latLng":{"lat":"48.212021","lng":"16.368891"},"type":"marker"},{"color":"#CFD200","latLng":{"lat":"48.206852","lng":"16.368848"},"type":"marker"},{"color":"#d14a21","latLngs":[{"lat":"48.206852","lng":"16.368848"},{"lat":"48.20047","lng":"16.379501"}],"type":"polyline"},{"color":"#aaaaaa","latLng":{"lat":"48.20047","lng":"16.379501"},"type":"marker"}]</code>
<a href="https://intel.ingress.com/?ll=48.199996,16.369424&z=16&pls=48.199996,16.369424,48.212021,16.368891_48.206852,16.368848,48.20047,16.379501">Stock Intel Link</a>
!, 'symbol detail');






sub ref_intel {
	my $name                  = shift;
	my %reference_intel_links = (
		empty      => '',
		two_loners => '',
		loner_triplet =>
			'https://intel.ingress.com/?ll=48.211888,16.378676&z=16&pls=48.211888,16.378676,48.206793,16.378702_48.206793,16.378702,48.206852,16.368848',
		two_couples =>
			'https://intel.ingress.com/?ll=48.199996,16.369424&z=16&pls=48.199996,16.369424,48.212021,16.368891_48.206793,16.378702,48.206852,16.368848',
		full =>
			'https://intel.ingress.com/?ll=48.199996,16.369424&z=16&pls=48.199996,16.369424,48.212021,16.368891_48.212021,16.368891,48.211888,16.378676_48.211888,16.378676,48.206793,16.378702_48.206793,16.378702,48.206852,16.368848_48.206852,16.368848,48.20047,16.379501',

	);
	return exists $reference_intel_links{$name} ? $reference_intel_links{$name} : '';
}

sub ref_data {
	my $name                = shift;
	my %reference_iitc_data = (
		empty => [],
		loner => [
			{   'color'  => '#57D600',
				'type'   => 'marker',
				'latLng' => {
					'lat' => '48.199996',
					'lng' => '16.369424'
				}
			}
		],
		two_loners => [
			{   'type'   => 'marker',
				'color'  => '#57D600',
				'latLng' => {
					'lat' => '48.199996',
					'lng' => '16.369424'
				}
			},
			{   'type'   => 'marker',
				'color'  => '#CFD200',
				'latLng' => {
					'lat' => '48.211888',
					'lng' => '16.378676'
				}
			}
		],

		loner_triplet => [
			{   'latLng' => {
					'lng' => '16.369424',
					'lat' => '48.199996'
				},
				'type'  => 'marker',
				'color' => '#57D600'
			},
			{   'type'   => 'marker',
				'color'  => '#CFD200',
				'latLng' => {
					'lat' => '48.211888',
					'lng' => '16.378676'
				}
			},
			{   'latLngs' => [
					{   'lng' => '16.378676',
						'lat' => '48.211888'
					},
					{   'lat' => '48.206793',
						'lng' => '16.378702'
					},
					{   'lat' => '48.206852',
						'lng' => '16.368848'
					}
				],
				'type'  => 'polyline',
				'color' => '#3476d1'
			},
			{   'color'  => '#aaaaaa',
				'type'   => 'marker',
				'latLng' => {
					'lat' => '48.206793',
					'lng' => '16.378702'
				}
			},
			{   'latLng' => {
					'lng' => '16.368848',
					'lat' => '48.206852'
				},
				'type'  => 'marker',
				'color' => '#aaaaaa'
			}
		],
		two_couples => [
			{   'latLng' => {
					'lng' => '16.369424',
					'lat' => '48.199996'
				},
				'color' => '#57D600',
				'type'  => 'marker'
			},
			{   'latLngs' => [
					{   'lat' => '48.199996',
						'lng' => '16.369424'
					},
					{   'lat' => '48.212021',
						'lng' => '16.368891'
					}
				],
				'type'  => 'polyline',
				'color' => '#3476d1'
			},
			{   'type'   => 'marker',
				'color'  => '#aaaaaa',
				'latLng' => {
					'lat' => '48.212021',
					'lng' => '16.368891'
				}
			},
			{   'latLng' => {
					'lat' => '48.206793',
					'lng' => '16.378702'
				},
				'color' => '#CFD200',
				'type'  => 'marker'
			},
			{   'latLngs' => [
					{   'lng' => '16.378702',
						'lat' => '48.206793'
					},
					{   'lng' => '16.368848',
						'lat' => '48.206852'
					}
				],
				'color' => '#3476d1',
				'type'  => 'polyline'
			},
			{   'latLng' => {
					'lat' => '48.206852',
					'lng' => '16.368848'
				},
				'color' => '#aaaaaa',
				'type'  => 'marker'
			}
		],
		full => [
			{   'color'  => '#57D600',
				'type'   => 'marker',
				'latLng' => {
					'lat' => '48.199996',
					'lng' => '16.369424'
				}
			},
			{   'color'   => '#3476d1',
				'latLngs' => [
					{   'lat' => '48.199996',
						'lng' => '16.369424'
					},
					{   'lng' => '16.368891',
						'lat' => '48.212021'
					},
					{   'lat' => '48.211888',
						'lng' => '16.378676'
					},
					{   'lat' => '48.206793',
						'lng' => '16.378702'
					},
					{   'lat' => '48.206852',
						'lng' => '16.368848'
					},
					{   'lng' => '16.379501',
						'lat' => '48.20047'
					}
				],
				'type' => 'polyline'
			},
			{   'type'   => 'marker',
				'color'  => '#aaaaaa',
				'latLng' => {
					'lng' => '16.368891',
					'lat' => '48.212021'
				}
			},
			{   'type'   => 'marker',
				'color'  => '#aaaaaa',
				'latLng' => {
					'lat' => '48.211888',
					'lng' => '16.378676'
				}
			},
			{   'latLng' => {
					'lng' => '16.378702',
					'lat' => '48.206793'
				},
				'color' => '#aaaaaa',
				'type'  => 'marker'
			},
			{   'color'  => '#aaaaaa',
				'type'   => 'marker',
				'latLng' => {
					'lat' => '48.206852',
					'lng' => '16.368848'
				}
			},
			{   'latLng' => {
					'lng' => '16.379501',
					'lat' => '48.20047'
				},
				'color' => '#aaaaaa',
				'type'  => 'marker'
			}
		],

	);
	return $reference_iitc_data{$name};
}

