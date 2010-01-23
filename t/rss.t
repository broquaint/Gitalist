#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use TestGitalist;

my $res = request('/repo1/rss');
ok $res->is_success;

like $res->content, qr{link>http://localhost/repo1</link};
like $res->content, qr{description>some test repository</description};
like $res->content, qr{title>add dir1/file2</title};
like $res->content, qr{description>add dir1/file2</description};
like $res->content, qr{guid isPermaLink="true">http://localhost/repo1/36c6c6708b8360d7023e8a1649c45bcf9b3bd818</guid};

done_testing;
