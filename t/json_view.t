#!/usr/bin/env perl

use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use JSON::XS qw/decode_json encode_json/;

BEGIN {
    $ENV{GITALIST_CONFIG} = $Bin;
    $ENV{GITALIST_REPO_DIR} = '';
    use_ok 'Catalyst::Test', 'Gitalist';
}

my $res = request(GET 'http://localhost/repo1', 'Content-Type' => 'application/json');
is $res->code, 200;
my $data = decode_json $res->content;
is ref($data), 'HASH';
delete $data->{owner}
  if $data && exists $data->{owner};
is_deeply $data, {
          'is_bare' => 1,
          '__CLASS__' => 'Gitalist::Git::Repository',
          'last_change' => '2011-06-05T23:00:44Z',
          'name' => 'repo1',
          'description' => 'some test repository'
        };

done_testing;


