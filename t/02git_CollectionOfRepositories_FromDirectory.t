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

use Path::Class 'dir';
use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::CollectionOfRepositories::FromDirectory' }

my $repo_dir = dir( "$Bin/lib/repositories" );
my $repo = Gitalist::Git::CollectionOfRepositories::FromDirectory->new( repo_dir => $repo_dir );
isa_ok($repo, 'Gitalist::Git::CollectionOfRepositories::FromDirectory');

is($repo->repo_dir, $repo_dir, "repo->repo_dir is correct" );

# 'bare.git' is a bare git repository in the repository dir
use Path::Class;
my $repoBare = Path::Class::Dir->new('t/lib/repositories/bare.git');
ok( $repo->_is_git_repo( $repoBare ), 'is_git_repo true for bare git repo' );

# 'empty.git' is an empty directory in the repository dir
my $repoEmpty = Path::Class::Dir->new('t/lib/repositories/empty.git');
ok( ! $repo->_is_git_repo( $repoEmpty ), 'is_git_repo is false for empty dir' );

my $repository_list = $repo->repositories;
ok(scalar @{$repository_list} == 3, '->repositories is an array with the correct number of members' );
isa_ok($repository_list->[0], 'Gitalist::Git::Repository');
is($repository_list->[0]->{name}, 'bare.git', '->repositories has correct name for "bare.git" repo' );

dies_ok {
    my $repository = $repo->get_repository('NoSuchRepository');
} 'throws exception for invalid repository';

dies_ok {
    my $repository = $repo->get_repository();
} 'throws exception for no repository';

dies_ok {
    my $repository = $repo->get_repository('../../../');
} 'throws exception for directory traversal';

my $repository = $repo->get_repository('repo1');
isa_ok($repository, 'Gitalist::Git::Repository');


# check for bug where get_repository blew up if repo_dir
# was a relative path
lives_ok {
    my $repo2_dir = "$Bin/lib/../lib/repositories";
    my $repo2 = Gitalist::Git::CollectionOfRepositories::FromDirectory->new( repo_dir => $repo2_dir );
    my $repo2_proj = $repo2->get_repository('repo1');
} 'relative repo_dir properly handled';

my $repo_eok = Gitalist::Git::CollectionOfRepositories::FromDirectory->new(
    repo_dir  => $repo_dir,
    export_ok => 'export-ok',
);

my @eok_repos = @{$repo_eok->repositories};

is(1, @eok_repos, "Found the 1 export-ok repo");
is('repo1', $eok_repos[0]->name, "Found repo1 export-ok repo");
