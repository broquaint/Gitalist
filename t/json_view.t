#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use FindBin qw/$Bin/;
use JSON::Any;

BEGIN {
    $ENV{GITALIST_CONFIG} = $Bin;
    $ENV{GITALIST_REPO_DIR} = '';
    use_ok 'Catalyst::Test', 'Gitalist';
}

my $j = JSON::Any->new;

my $res = request(GET 'http://localhost/summary?p=repo1', 'Content-Type' => 'application/json');
is $res->code, 200;
my $data = $j->decode($res->content);
is ref($data), 'HASH';
is_deeply $data, {
          'owner' => 'Tomas Doran',
          'is_bare' => 1,
          '__CLASS__' => 'Gitalist::Git::Repository',
          'last_change' => '2009-11-12T19:00:34Z',
          'references' => {
                            '0710a7c8ee11c73e8098d08f9384c2a839c65e4e' => [
                                                                            'heads/branch1'
                                                                          ],
                            '36c6c6708b8360d7023e8a1649c45bcf9b3bd818' => [
                                                                            'heads/master'
                                                                          ]
                          },
          'name' => 'repo1',
          'description' => 'some test repository'
        };

done_testing;


