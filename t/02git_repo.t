use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;
use Test::Exception;

use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Repo' }

my $repo_dir = "$Bin/lib/repositories";
my $repo = Gitalist::Git::Repo->new( repo_dir => $repo_dir );
isa_ok($repo, 'Gitalist::Git::Repo');

is($repo->repo_dir, $repo_dir, "repo->repo_dir is correct" );

# 'bare.git' is a bare git repository in the repository dir
use Path::Class;
my $repoBare = Path::Class::Dir->new('t/lib/repositories/bare.git');
ok( $repo->_is_git_repo( $repoBare ), 'is_git_repo true for bare git repo' );

# 'working' is a working copy w/ git repo in the repository dir
my $repoWorking = Path::Class::Dir->new('t/lib/repositories/working');

# 'empty.git' is an empty directory in the repository dir
my $repoEmpty = Path::Class::Dir->new('t/lib/repositories/empty.git');
ok( ! $repo->_is_git_repo( $repoEmpty ), 'is_git_repo is false for empty dir' );

my $project_list = $repo->projects;
isa_ok(@$project_list[0], 'Gitalist::Git::Project');
ok(scalar @{$project_list} == 3, 'list_projects returns an array with the correct number of members' );
is($project_list->[0]->{name}, 'bare.git', 'list_projects has correct name for "bare.git" repo' );

dies_ok {
    my $project = $repo->project('NoSuchProject');
} 'throws exception for invalid project';

dies_ok {
    my $project = $repo->project();
} 'throws exception for no project';

dies_ok {
    my $project = $repo->project('../../../');
} 'throws exception for directory traversal';

my $project = $repo->project('repo1');
isa_ok($project, 'Gitalist::Git::Project');
