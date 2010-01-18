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

my $res = request('/opml');
ok $res->is_success;

like $res->content, qr{Gitalist</title>};
like $res->content, qr{xmlUrl="http://localhost/bare.git/rss"};
like $res->content, qr{text="repo1 - some test repository"};
like $res->content, qr{xmlUrl="http://localhost/repo1/rss"};

done_testing;
