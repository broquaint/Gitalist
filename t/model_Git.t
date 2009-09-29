use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;

BEGIN { use_ok 'Gitalist::Model::Git' }

my $c = bless {}, 'Gitalist';
my $m = Gitalist::Model::Git->new($c, { repo_dir => "$Bin/lib/repositories" });
isa_ok($m, 'Gitalist::Model::Git');

# 'bare.git' is a bare git repository in the repository dir
use Path::Class;
my $repoBare = Path::Class::Dir->new('t/lib/repositories/bare.git');
ok( $m->is_git_repo( $repoBare ), 'is_git_repo true for bare git repo' );

# 'working' is a working copy w/ git repo in the repository dir
my $repoWorking = Path::Class::Dir->new('t/lib/repositories/working');
#ok( $m->is_git_repo( $repoWorking ), 'is_git_repo true for git repo in working copy' );

# 'empty.git' is an empty directory in the repository dir
my $repoEmpty = Path::Class::Dir->new('t/lib/repositories/empty.git');
ok( ! $m->is_git_repo( $repoEmpty ), 'is_git_repo is false for empty dir' );

my $projectList = $m->list_projects;
ok( scalar @{$projectList} == 2, 'list_projects returns an array with the correct number of members' );
ok( $projectList->[0]->{name} eq 'bare.git', 'list_projects has correct name for "bare.git" repo' );
#ok( $projectList->[1]->{name} eq 'working/.git', 'list_projects has correct name for "working" repo' );


# Liberally borrowed from rafl's gitweb
my $repo = 'repo1';

like($m->get_head_hash($repo), qr/^([0-9a-fA-F]{40})$/, 'get_head_hash');

{
    my @tree = $m->list_tree($repo, '3bc0634310b9c62222bb0e724c11ffdfb297b4ac');

    is(scalar @tree, 1);
    is_deeply($tree[0], {
            mode => oct 100644,
            type => 'blob',
            object => '257cc5642cb1a054f08cc83f2d943e56fd3ebe99',
            file => 'file1'
    });

    is($m->get_object_mode_string($tree[0]), '-rw-r--r--');
}

is($m->get_object_type($repo, '729a7c3f6ba5453b42d16a43692205f67fb23bc1'), 'tree');
is($m->get_object_type($repo, '257cc5642cb1a054f08cc83f2d943e56fd3ebe99'), 'blob');
is($m->get_object_type($repo, '5716ca5987cbf97d6bb54920bea6adde242d87e6'), 'blob');

is($m->cat_file($repo, '257cc5642cb1a054f08cc83f2d943e56fd3ebe99'), "foo\n");
is($m->cat_file($repo, '5716ca5987cbf97d6bb54920bea6adde242d87e6'), "bar\n");

is($m->diff($repo, '3bc0634310b9c62222bb0e724c11ffdfb297b4ac', '3f7567c7bdf7e7ebf410926493b92d398333116e'), <<EOD);
diff --git a/file1 b/file1
index 257cc56..5716ca5 100644
--- a/file1
+++ b/file1
@@ -1 +1 @@
-foo
+bar
EOD

use Data::Dumper;
warn( Dumper( $m->list_revs($repo) ));
