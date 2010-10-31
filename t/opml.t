#!/usr/bin/env perl
use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use lib "$Bin/lib";
use TestGitalist;
use HTTP::Request::Common;

my $res = request(GET 'http://localhost/opml', 'Content-Type' => 'application/rss');

ok $res->is_success;

is $res->content_type, 'application/rss';
like $res->content, qr{Gitalist</title>};
like $res->content, qr{xmlUrl="http://localhost/bare.git/rss"};
like $res->content, qr{text="repo1 - some test repository"};
like $res->content, qr{xmlUrl="http://localhost/repo1/rss"};

done_testing;
