use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;
use Test::Exception;
use Data::Dumper;

use Path::Class;
use Gitalist::Git::Project;
my $project = Gitalist::Git::Project->new(
    dir("$Bin/lib/repositories/repo1"),
);

BEGIN {
    use_ok 'Gitalist::Git::Object::Tree';
    use_ok 'Gitalist::Git::Object::Blob';
    use_ok 'Gitalist::Git::Object::Commit';
    use_ok 'Gitalist::Git::Object::Tag';
    }

my $object = Gitalist::Git::Object::Tree->new(
    project => $project,
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
is($object->modestr, 'd---------', "modestr is correct" );
is($object->size, 33, "size is correct");

# Create object from sha1.
my $obj2 = Gitalist::Git::Object::Blob->new(
    project => $project,
    sha1 => '5716ca5987cbf97d6bb54920bea6adde242d87e6',
);
isa_ok($obj2, 'Gitalist::Git::Object::Blob', 'blob object');
is($obj2->sha1,'5716ca5987cbf97d6bb54920bea6adde242d87e6', 'sha1 is correct');
is($obj2->type, 'blob', 'type is correct');
is($obj2->mode, 0, 'mode is correct');
is($obj2->modestr, '?---------', "modestr is correct" );
is($obj2->content, "bar\n", 'obj2 contents is correct');
is($obj2->size, 4, "size is correct");
dies_ok {
    print $obj2->tree_sha1;
} 'tree_sha1 on a blob is an exception';
dies_ok {
    print $obj2->comment;
} 'comment is an empty string';

my $commit_obj = Gitalist::Git::Object::Commit->new(
    project => $project,
    sha1 => '3f7567c7bdf7e7ebf410926493b92d398333116e',
);
isa_ok($commit_obj, 'Gitalist::Git::Object::Commit', "commit object");
my ($tree, $patch) = $commit_obj->diff(
    parent => undef,
    file => undef,
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

ok(index($commit_obj->get_patch, 'From 3f7567c7bdf7e7ebf410926493b92d398333116e Mon Sep 17 00:00:00 2001
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
--') == 0, 'commit_obj->get_patch can return a patch');

like($commit_obj->get_patch(undef, 3), qr!PATCH 2/2!, 'commit_obj->get_patch can return a patchset');
