#!/usr/bin/perl
use strict;
use warnings;
use 5.030;
use Data::Dumper;
use DBI;
use Config::Any;
use Getopt::Long;
use Number::Format;
use Time::HiRes;
use POSIX qw(strftime);
use Encode;
use Redis;
use Time::HiRes qw(time);
use DateTime;
use JSON;
use File::Slurper qw(read_binary write_binary);
use List::Util qw(all);

# Async Telegram bot implementation using WWW::Telegram::BotAPI
# See also https://gist.github.com/Robertof/d9358b80d95850e2eb34
use Mojo::Base -strict;
use WWW::Telegram::BotAPI;

use lib qw(../lib lib);
use IFS::Decoder::Bot;

use Telegram::Message;
use Telegram::Router;
use Telegram::Target;
use Telegram::Target::SimpleCommand;
use Telegram::Target::OneArgCommand;
use Telegram::Target::Pattern;

use IFS::Decoder::Submitter;
use IFS::Decoder::Solution;
use IFS::Decoder::Solution::Symbol;
use IFS::Decoder::Solution::Symbol::Portal;
use IFS::Decoder::Solution::Symbol::Portal::Submission;


my $tg_key;
my $config_path;
my $verbose;

my $list_update_time;
my $redis_key = 'ifs_decoder_bot::';
sub hires_timestamp {
	return sprintf( "[%s] ", DateTime->from_epoch( epoch => time )->strftime('%Y-%m-%d %H:%M:%S.%6N') );
}


$SIG{__WARN__} = sub { warn hires_timestamp(), @_ };
$SIG{__DIE__}  = sub { die  hires_timestamp(), @_ };
my $state_file = 'solution_state.json';
my $template_file = 'solution_template.txt';
my $reset_solution = 0;
my $city = 'demo';
GetOptions(
	"config_path=s" => \$config_path,
	"tg_key=s"      => \$tg_key,
	"verbose"       => \$verbose,
	"state_file=s"  => \$state_file,
	"city=s"  		=> \$city,
	reset_solution  => \$reset_solution,
	)    # flag
	or die("Error in command line arguments\n");

my $solution = [];


$SIG{HUP}  = \&store_solution;
# $SIG{TERM} = $SIG{INT} = sub {
# 	warn 'storing solution';
# 	store_solution();
# 	warn 'terminating';
# 	exit;
# };


if ( !$reset_solution && -e $state_file ) {
	$solution = decode_json( read_binary($state_file) );
}
elsif ( -e $template_file ) {
	my $template = read_binary($template_file);
	$solution->[0] = {title => ''};
	for my $line ( split /\n/, read_binary($template_file) ) {
		push @$solution, { meta => { type => $1, solution => '' }, list => [map { [] } ( 0 .. ( $2 - 1 ) )] }
			if $line =~ /^(.+)\s+(\d+)$/;
	}
}

my $api = WWW::Telegram::BotAPI->new (
    token => ($tg_key or die "ERROR: a token is required!\n"),
    async => 1
);


my $dt = DateTime->now;    # same as ( epoch => time )
 
my $year  = $dt->year;
my $month = $dt->month;

my $bot_id = sprintf( "ifs_%s_%s_%02d", $city, $year, $month );
warn "starting bot with id: $bot_id";
my $bot = IFS::Decoder::Bot->new(bot_id => $bot_id);

# Increase the inactivity timeout of Mojo::UserAgent
$api->agent->inactivity_timeout (45);

# Fetch bot information asynchronously
my $me;

$api->getMe (wrap_async (sub {
    $me = shift;
    warn "Received bot information from Telegram server: hello world, I'm '$me->{first_name}'!";
}));


fetch_updates();

Mojo::IOLoop->start;


# Async update handling
sub fetch_updates {
    state $offset = 0;
    $api->getUpdates ({
        timeout => 30,
        allowed_updates => ["message"], # remove me in production if you need multiple update types
        $offset ? (offset => $offset) : ()
    } => wrap_async (sub {
        my $updates = shift;
        for my $update (@$updates) {
            $offset = $update->{update_id} + 1 if $update->{update_id} >= $offset;
            # Handle text messages. No checks are needed because of `allowed_updates`

			warn __PACKAGE__.':'.__LINE__.$".Data::Dumper->Dump([\$update], ['update']);
			next unless $update->{message}{text};
			my $message = Telegram::Message->new($update->{message});
		
	
            my $message_text = $update->{message}{text};
# 
            warn "> Incoming message from \@$update->{message}{from}{username} at ",
                scalar localtime;
			warn encode( 'utf8', ">> $message_text" );

			my @replies;
			eval {
				@replies = $bot->router->route($message)->@*;
			};
			warn 'replies: '.scalar @replies;

			for my $reply (@replies) {
				my @res = $api->sendMessage(
					$reply->for_api => sub {
						my ( $ua, $tx ) = @_;
						if ( $tx->error || !$tx->res->json->{ok} ) {
							my $j = $tx->res->json;
							warn __PACKAGE__ . ':' . __LINE__ . $" . Data::Dumper->Dump( [\$j], ['j'] );
							warn 'my reply: '.Dumper $reply->for_api;
							warn "> Replied\n$reply->{text}\n at ", scalar localtime;
						}
						else {
							warn "> Replied\n$reply->{text}\n at ", scalar localtime;
							#warn encode( 'utf8', "> Replied\n$reply->{text}\n at " ), scalar localtime;
						}
					}
				);
			}
		}

		# Run the request again using ourselves as the handler :-)
		fetch_updates();
	} ) );
}


sub wrap_async {
    my $callback = shift;
    sub {
        my (undef, $tx) = @_;
        my $response = $tx->res->json;
        unless ($tx->result->is_success && $response && $response->{ok}) {
            # TODO: if using this in production code, do NOT die on error, but handle them
            # gracefully
            warn "ERROR: ", ($response->{error_code} ? "code $response->{error_code}: " : ""),
                $response->{description} ?
                    $response->{description} :
                    ($tx->error || {})->{message} || "something went wrong!";
            Mojo::IOLoop->stop;
            exit;
        }
        $callback->($response->{result});
    }
}



