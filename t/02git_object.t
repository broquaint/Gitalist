use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use Test::Deep;

use Path::Class;
use Gitalist::Git::Repository;
my $repository = Gitalist::Git::Repository->new(
    dir("$Bin/lib/repositories/repo1"),
);

BEGIN {
    use_ok 'Gitalist::Git::Object::Tree';
    use_ok 'Gitalist::Git::Object::Blob';
    use_ok 'Gitalist::Git::Object::Commit';
    use_ok 'Gitalist::Git::Object::Tag';
    }

my $object = Gitalist::Git::Object::Tree->new(
    repository => $repository,
    sha1 => '729a7c3f6ba5453b42d16a43692205f67fb23bc1',
    type => 'tree',
    file => 'dir1',
    mode => 16384,
);
isa_ok($object, 'Gitalist::Git::Object::Tree', 'tree object');
is($object->sha1,'729a7c3f6ba5453b42d16a43692205f67fb23bc1', 'sha1 is correct');
is($object->type, 'tree', 'type is correct');
is($object->file, 'dir1', 'file is correct');
is($object->mode, 16384, 'mode is correct');
is($object->modestr, 'drwxr-xr-x', "modestr is correct" );
is($object->size, 33, "size is correct");
is($object,'729a7c3f6ba5453b42d16a43692205f67fb23bc1', 'stringifies correctly');

cmp_deeply $object->pack, {
    __CLASS__
         => 'Gitalist::Git::Object::Tree',
    file   => 'dir1',
    mode   => 16384,
    modestr
         => 'drwxr-xr-x',
    repository
         => {
             __CLASS__   => 'Gitalist::Git::Repository',
             description => 'some test repository',
             is_bare     => 1,
             last_change => '2009-11-12T19:00:34Z',
             name        => 'repo1',
             owner       => code(\&is_system_account_name),
         },
    sha1   => '729a7c3f6ba5453b42d16a43692205f67fb23bc1',
    size   => 33,
    type   => 'tree'
}, 'Serialized tree correctly';

# Create object from sha1.
my $obj2 = Gitalist::Git::Object::Blob->new(
    repository => $repository,
    sha1 => '5716ca5987cbf97d6bb54920bea6adde242d87e6',
);
isa_ok($obj2, 'Gitalist::Git::Object::Blob', 'blob object');
is($obj2->sha1,'5716ca5987cbf97d6bb54920bea6adde242d87e6', 'sha1 is correct');
is($obj2->type, 'blob', 'type is correct');
is($obj2->mode, 0, 'mode is correct');
is($obj2->modestr, '----------', "modestr is correct" );
is($obj2->content, "bar\n", 'obj2 contents is correct');
is($obj2->size, 4, "size is correct");
dies_ok {
    print $obj2->tree_sha1;
} 'tree_sha1 on a blob is an exception';
dies_ok {
    print $obj2->comment;
} 'comment is an empty string';

cmp_deeply $obj2->pack,  {
    __CLASS__
         => 'Gitalist::Git::Object::Blob',
    mode   => 0,
    modestr
         => '----------',
    repository
         => {
             __CLASS__   => 'Gitalist::Git::Repository',
             description => 'some test repository',
             is_bare     => 1,
             last_change => '2009-11-12T19:00:34Z',
             name        => 'repo1',
             owner       => code(\&is_system_account_name),
         },
    sha1   => '5716ca5987cbf97d6bb54920bea6adde242d87e6',
    size   => 4,
    type   => 'blob'
}, 'Serialized blob correctly';

my $commit_obj = Gitalist::Git::Object::Commit->new(
    repository => $repository,
    sha1 => '3f7567c7bdf7e7ebf410926493b92d398333116e',
);
isa_ok($commit_obj, 'Gitalist::Git::Object::Commit', "commit object");
isa_ok($commit_obj->tree->[0], 'Gitalist::Git::Object::Tree');

cmp_deeply $commit_obj->pack,  {
    __CLASS__
         => 'Gitalist::Git::Object::Commit',
    mode   => 0,
    modestr
         => '----------',
    repository
         => {
             __CLASS__   => 'Gitalist::Git::Repository',
             description => 'some test repository',
             is_bare     => 1,
             last_change => '2009-11-12T19:00:34Z',
             name        => 'repo1',
             owner       => code(\&is_system_account_name),
         },
    sha1   => '3f7567c7bdf7e7ebf410926493b92d398333116e',
    size   => 218,
    tree   => [ {
        __CLASS__
             => 'Gitalist::Git::Object::Tree',
        mode   => 0,
        modestr
             => '----------',
        repository
             => {
                 __CLASS__   => 'Gitalist::Git::Repository',
                 description => 'some test repository',
                 is_bare     => 1,
                 last_change => '2009-11-12T19:00:34Z',
                 name        => 'repo1',
                 owner       => code(\&is_system_account_name),
             },
        sha1   => '9062594aebb5df0de7fb92413f17a9eced196c22',
        size   => 33,
        type   => 'tree'
    } ],
    type   => 'commit'
}, 'Serialized commit correctly';

my ($tree, $patch) = $commit_obj->diff(
    patch => 1,
);
$patch = $patch->[0];
is($patch->{head}, 'diff --git a/file1 b/file1', 'patch->{head} is correct');
is($patch->{a}, 'a/file1', 'patch->{a} is correct');
is($patch->{b}, 'b/file1', 'patch->{b} is correct');
is($patch->{file}, 'file1', 'patch->{file} is correct');
is($patch->{mode}, '100644', 'patch->{mode} is correct');
is($patch->{src}, '257cc5642cb1a054f08cc83f2d943e56fd3ebe99', 'patch->{src} is correct');
is($patch->{index}, 'index 257cc5642cb1a054f08cc83f2d943e56fd3ebe99..5716ca5987cbf97d6bb54920bea6adde242d87e6 100644', 'patch->{index} is correct');
is($patch->{diff}, '--- a/file1
+++ b/file1
@@ -1 +1 @@
-foo
+bar
', 'patch->{diff} is correct');
is($patch->{dst}, '5716ca5987cbf97d6bb54920bea6adde242d87e6', 'patch->{dst} is correct');

{
    my $contents = do { local $/; my $fh = $commit_obj->get_patch; <$fh> };
ok(index($contents,
'From 3f7567c7bdf7e7ebf410926493b92d398333116e Mon Sep 17 00:00:00 2001
From: Florian Ragwitz <rafl@debian.org>
Date: Tue, 6 Mar 2007 20:39:45 +0100
Subject: [PATCH] bar

---
 file1 |    2 +-
 1 files changed, 1 insertions(+), 1 deletions(-)

diff --git a/file1 b/file1
index 257cc56..5716ca5 100644
--- a/file1
+++ b/file1
@@ -1 +1 @@
-foo
+bar
--') == 0, 'commit_obj->get_patch can return a patch')
    or warn("Got instead: $contents");
}

# Note - 2 patches = 3 parts due to where we split.
{
    my $contents = do { local $/; my $fh = $commit_obj->get_patch(undef, 3); <$fh> };
    my @bits = split /Subject: \[PATC/, $contents;
    is(scalar(@bits), 3,
        'commit_obj->get_patch can return a patchset')
        or warn("Contents was $contents");
}
done_testing;

sub is_system_account_name {
    my $name = shift;
    return 0 if !$name;
    return 1;
}
