#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use TestGitalist;

my $res = request('/repo1/atom');
ok $res->is_success;
is $res->content_type, 'application/atom+xml';
TODO: {
    local $TODO = "Does not work yet. Need similar info to RSS feed";
    like $res->content, qr{link>http://localhost/repo1</link};
    like $res->content, qr{description>some test repository</description};
}
like $res->content, qr{add dir1/file2</div};
like $res->content, qr{<id>http://localhost/repo1/36c6c6708b8360d7023e8a1649c45bcf9b3bd818/commit</id};
like $res->content, qr{title>add dir1/file2</title};

done_testing;
