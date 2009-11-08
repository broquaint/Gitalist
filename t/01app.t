#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;

BEGIN {
    $ENV{GITALIST_CONFIG} = $Bin;
    use_ok 'Catalyst::Test', 'Gitalist'
}

ok( request('/')->is_success, 'Request should succeed' );

for my $p (qw/ repo1 nodescription /) {
    my $path = '/summary?p=' . $p;
    ok( request($path)->is_success, "$path should succeed");
}

is request('/summary?p=DoesNotExist')->code, 404,
    '/summary?p=DoesNotExist 404s';
{
  # URI tests for repo1
  local *test = curry_test_uri('repo1');
  test('/summary');
  test('/shortlog');
  test('/log');
  test('/commit');
  test('/commitdiff', 'h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
  test('/tree', 'h=145dc3ef5d307be84cb9b325d70bd08aeed0eceb;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');

  # legacy URIs
  test('/', 'a=summary');
  test('/', 'a=heads');
  test('/', 'a=shortlog');
  test('/', 'a=log');
  test('/', 'a=commit');
  test('/', 'a=commitdiff');
  test('/', 'a=tree');
#  $test_repo1->('/', 'a=blob;f=file1');
}

done_testing;

sub test_uri {
    my ($p, $uri, $qs) = @_;
    $qs ||= '';
    my $request = "$uri?p=repo1;$qs";
    warn("request: $request");
    my $response = request($request);
    ok($response->is_success, "ok $p - $uri");
}

sub curry_test_uri {
    my $p = shift;
    sub {
        my ($uri, $qs) = @_;
        test_uri($p, $uri, $qs);
    };
};
