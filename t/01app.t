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

done_testing;

