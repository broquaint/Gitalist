#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use TestGitalist;

my $res = request('/opml');
ok $res->is_success;

like $res->content, qr{Gitalist</title>};
like $res->content, qr{xmlUrl="http://localhost/bare.git/rss"};
like $res->content, qr{text="repo1 - some test repository"};
like $res->content, qr{xmlUrl="http://localhost/repo1/rss"};

done_testing;
