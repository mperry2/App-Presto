use strict;
use warnings;
use Test::More;
use Test::MockObject;
use App::Presto::Client;

my $config = Test::MockObject->new;
$config->set_always( endpoint => 'http://my-server.com');
my $rest_client = Test::MockObject->new;
$rest_client->set_true('GET','DELETE','PUT','POST','HEAD');
my $client = App::Presto::Client->new(config=>$config, _rest_client => $rest_client);

isa_ok($client, 'App::Presto::Client');

$client->GET('/foo');
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'GET', 'rest_client GET';
	is $args->[1], 'http://my-server.com/foo', 'constructs correct URI';
}

$client->DELETE('http://another-server.com/blah');
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'DELETE', 'rest_client DELETE';
	is $args->[1], 'http://another-server.com/blah', 'allows URI override';
}

$client->PUT('/bar', 'foobar');
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'PUT', 'rest_client PUT';
	is $args->[2], 'foobar', 'PUT body';
}

$client->HEAD;
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'HEAD', 'rest_client HEAD (no uri)';
	is $args->[1], 'http://my-server.com/', 'default URI';
}

$client->POST('/foo', q({"a":1}));
{
	my ( $m, $args ) = $rest_client->next_call;
	is $m, 'POST', 'rest_client POST';
	is $args->[1], 'http://my-server.com/foo', 'POST URI';
	is $args->[2], '{"a":1}', 'POST body';
}

done_testing;
