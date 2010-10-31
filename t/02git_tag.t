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

# Create an instance from for-each-ref output
my $revline="36c6c6708b8360d7023e8a1649c45bcf9b3bd818 commit refs/tags/0.01   add dir1/file2\0Florian Ragwitz <rafl\@debian.org> 1173210275 +0100";
#my $revline="a92fb1c9282f7319099ce7f783c8be7d5360f6e3\0refs/heads/model-cleanup\0Zachary Stevens <zts\@cryptocracy.com> 1277601094 +0100";
my $instance = Gitalist::Git::Tag->new($revline);
isa_ok($instance, 'Gitalist::Git::Tag');

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
