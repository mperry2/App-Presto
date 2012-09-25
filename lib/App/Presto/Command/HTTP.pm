package App::Presto::Command::HTTP;

# ABSTRACT: HTTP-related commands

use strict;
use warnings;
use Moo;
with 'App::Presto::InstallableCommand', 'App::Presto::CommandHasHelp','App::Presto::WithPrettyPrinter';

my %URL_HISTORY;

sub urls_for {
    my $method = shift;
    return $URL_HISTORY{$method} || [];
}
sub add_url {
    my($method, $url) = @_;
    push(@{ $URL_HISTORY{$method} ||= []}, $url);
}

sub install {
    my $self = shift;
    my $client = $self->client;
    $self->term->add_commands(
        {
            form => {
                desc => "helper for formatting URL-encoded strings",
                minargs => 1,
                args => "some-key=some-value",
                proc => sub {
                    my $uri = $client->_append_query_params( '', @_ );
                    $uri =~ s{^\?}{};
                    print "$uri\n";
                  }
            },
            map {
                my $m = $_;
                $m => {
                    desc => "perform a $m HTTP action",
                    args => [ sub { urls_for($m) } ],
                    proc => $self->_mk_proc_for($m)
                  }
              } qw(GET POST PUT DELETE HEAD)
        }
    );
}

sub _mk_proc_for {
    my $self = shift;
    my $method = shift;
    my $client = $self->client;
    return sub {
        add_url($method => $_[0]);
        if($method =~ m/^P/){
            warn " * no content-type header currently set\n" unless $client->get_header('Content-Type');
        }
        $client->$method(@_);
        $self->handle_response($client);
    }
}

sub handle_response {
    my $self = shift;
    my $client = shift;
    my $response = $client->response;
    my $config = $self->config;
    if ( $config->get('verbose') ) {
        print _dump_request_response( $response->request, $response );
    }
    if ( $client->has_response_content ) {
        if ( $config->get('deserialize_response') ) {
            my $data = $client->response_data;
            print $self->pretty_print($data);
        } elsif ( !$config->get('verbose') ) {    # don't print just the content a second time...
            print $response->decoded_content;
            print "\n";
        }
    } elsif ( !$config->get('verbose') ) {
        print $response->as_string, "\n";
    }
}

sub _dump_request_response {
    my($request,$response) = @_;
    return sprintf(<<'_OUT_', $request->as_string, $response->as_string);
----- REQUEST  -----
%s
----- RESPONSE -----
%s
-----   END    -----
_OUT_
}

sub help_categories {
    return {
        desc => 'Various HTTP verb commands',
        cmds => [qw(GET POST HEAD PUT DELETE)],
    };
}

1;
