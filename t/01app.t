#!/usr/bin/env perl
use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN { use_ok 'Catalyst::Test', 'Gitalist' }

# Full tests are only run if the APP_TEST env var is set.
# This is needed to load the test configuration.
diag("*** SKIPPING app tests.
*** Set APP_TEST for the tests to run fully") if !$ENV{APP_TEST};
SKIP: {
  skip "Set APP_TEST for the tests to run fully",
    1 if !$ENV{APP_TEST};

  ok( request('/')->is_success, 'Request should succeed' );


  # URI tests for repo1
  use Data::Dumper;
  my $test_repo1 = curry_test_uri('repo1');
  &$test_repo1('/summary');
  &$test_repo1('/heads');
  &$test_repo1('/shortlog');
  &$test_repo1('/log');
  &$test_repo1('/commit');
  &$test_repo1('/commitdiff');
  &$test_repo1('/tree');
  &$test_repo1('/blobdiff', 'f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=refs/heads/master;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');

  # legacy URIs
  &$test_repo1('/', 'a=summary');
  &$test_repo1('/', 'a=heads');
  &$test_repo1('/', 'a=shortlog');
  &$test_repo1('/', 'a=log');
  &$test_repo1('/', 'a=commit');
  &$test_repo1('/', 'a=commitdiff');
  &$test_repo1('/', 'a=tree');
#  &$test_repo1('/', 'a=blob;f=file1');

} # Close APP_TEST skip

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
