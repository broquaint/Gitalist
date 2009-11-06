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
for my $p (qw/ bare.git repo1 nodescription /) {
    my $path = '/summary?p=' . $p;
    ok( request($path)->is_success, "$path should succeed");
}

is request('/summary?p=DoesNotExist')->code, 404,
    '/summary?p=DoesNotExist 404s';

done_testing;

