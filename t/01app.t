#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use FindBin qw/$Bin/;

BEGIN {
    $ENV{GITALIST_CONFIG} = $Bin;
    $ENV{GITALIST_REPO_DIR} = '';
    use_ok 'Catalyst::Test', 'Gitalist';
}

for my $p ('', qw/ repo1 nodescription bare.git opml /) {
    my $path = '/' . $p;
    ok( request($path)->is_success, "$path should succeed");
}

my $response = request('/DoesNotExist');
is $response->code, 404, 'invalid repository 404s';
like $response->content, qr/Page not found/, 'invalid repository handled correctly';


{
  # URI tests for repo1
  local *test = curry_test_uri('repo1');
  test('');
  test('shortlog');
  test('log');
  test('reflog');
  test('commit');
  TODO: {
      local $TODO = "FIXME";
  test('commitdiff', 'h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
  test('tree', 'h=145dc3ef5d307be84cb9b325d70bd08aeed0eceb;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
  test('search', 'type=commit&text=added');
  test('blobdiff', 'f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=refs/heads/master;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
  test('blob', 'f=dir1/file2;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
  test('patch');
  test('patch', 'h=3f7567c7bdf7e7ebf410926493b92d398333116e');
  test('patch', 'h=3f7567c7bdf7e7ebf410926493b92d398333116e;hp=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
  test('patches');
  test('patches', 'h=3f7567c7bdf7e7ebf410926493b92d398333116e');
  test('patches', 'h=3f7567c7bdf7e7ebf410926493b92d398333116e;hp=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
  }
}

done_testing;

sub test_uri {
    my ($uri, $qs) = @_;
    $qs ||= '';
    my $request = "/$uri"; 
    $request .= "?$qs" if defined $qs;
    my $response = request($request);
    ok($response->is_success, "ok $uri - $qs");
    return $response;
}

sub curry_test_uri {
    my $prefix = shift;
    my $to_curry = shift || \&test_uri;
    sub {
        my $uri = shift;
        $to_curry->("$prefix/$uri", @_);
    };
}
