#!/usr/bin/env perl
use FindBin qw/$Bin/;
BEGIN { do "$FindBin::Bin/../script/env" or die $@ }
use lib "$Bin/lib";
use TestGitalist;

my $res = request('/opml');
ok $res->is_success;

is $res->content_type, 'application/rss';
like $res->content, qr{Gitalist</title>};
like $res->content, qr{xmlUrl="http://localhost/bare.git/rss"};
like $res->content, qr{text="repo1 - some test repository"};
like $res->content, qr{xmlUrl="http://localhost/repo1/rss"};

done_testing;
