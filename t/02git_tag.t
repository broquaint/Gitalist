use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}
use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;
use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Tag' }

my $ref_sha1 = '3f7567c7bdf7e7ebf410926493b92d398333116e';
# Create an instance from for-each-ref output
my $revline="36c6c6708b8360d7023e8a1649c45bcf9b3bd818 commit refs/tags/0.01 $ref_sha1 add dir1/file2\0Florian Ragwitz <rafl\@debian.org> 1173210275 +0100";

my $instance = Gitalist::Git::Tag->new($revline);
isa_ok($instance, 'Gitalist::Git::Tag');

ok($instance->$_, $_) for $instance->meta->get_attribute_list;

# Create an instance, passing last_change as a DateTime
use DateTime;
my $timespec = [1173210275, '+0100'];
my $dt = DateTime->from_epoch(
    epoch => @$timespec[0],
    time_zone => @$timespec[1],
);
my $head = Gitalist::Git::Tag->new(
    sha1 => '36c6c6708b8360d7023e8a1649c45bcf9b3bd818',
    name => '0.01',
    type => 'commit',
    committer => 'Florian Ragwitz <rafl@debian.org>',
    last_change => $dt,
);
isa_ok($head, 'Gitalist::Git::Tag');

my $oldtag = "d6602ec5194c87b0fc87103ca4d67251c76f233a tag refs/tags/v0.99 a3eb250f996bf5e12376ec88622c4ccaabf20ea8 commit Test-release for wider distribution.";

ok(!Gitalist::Git::Tag::is_valid_tag($oldtag), 'Gitalist::Git::Tag::is_valid_tag ancient tag');
ok(Gitalist::Git::Tag::is_valid_tag($revline), 'Gitalist::Git::Tag::is_valid_tag regular tag');

# Tags don't necessarily have a refname, check we deal with its absence.
$revline =~ s/$ref_sha1//;
ok(Gitalist::Git::Tag::is_valid_tag($revline), 'Gitalist::Git::Tag::is_valid_tag regular tag sans ref sha1');
