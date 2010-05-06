#!/usr/bin/env perl
use FindBin qw/$Bin/;
BEGIN { do "$FindBin::Bin/../script/env" or die $@ }
use lib "$Bin/lib";
use TestGitalist;
use HTTP::Request::Common;

my $res = request(GET 'http://localhost/repo1/rss', 'Content-Type' => 'application/rss+xml');
ok $res->is_success;
is $res->content_type, 'application/rss+xml';
like $res->content, qr{link>http://localhost/repo1</link};
like $res->content, qr{description>some test repository</description};
like $res->content, qr{title>add dir1/file2</title};
like $res->content, qr{description>add dir1/file2</description};
like $res->content, qr{guid isPermaLink="true">http://localhost/repo1/36c6c6708b8360d7023e8a1649c45bcf9b3bd818/commit</guid};

done_testing;
