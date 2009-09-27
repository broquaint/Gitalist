use strict;
use warnings;
use Test::More qw/no_plan/;

BEGIN { use_ok 'Gitalist::Model::Git' }

my $Git = Gitalist::Model::Git->new;

# 'bare.git' is a bare git repository in the repository dir
use Path::Class;
my $repoBare = Path::Class::Dir->new('t/lib/repositories/bare.git');
ok( $Git->is_git_repo( $repoBare ), 'is_git_repo true for bare git repo' );

# 'working' is a working copy w/ git repo in the repository dir
my $repoWorking = Path::Class::Dir->new('t/lib/repositories/working');
ok( $Git->is_git_repo( $repoWorking ), 'is_git_repo true for git repo in working copy' );

# 'empty.git' is an empty directory in the repository dir
my $repoEmpty = Path::Class::Dir->new('t/lib/repositories/empty.git');
ok( ! $Git->is_git_repo( $repoEmpty ), 'is_git_repo is false for empty dir' );

# At present, these tests only work if the APP_TEST env var is set.
# This is needed to load the test configuration.
diag("*** SKIPPING app tests.
*** Set APP_TEST for the tests to run fully") if !$ENV{APP_TEST};
SKIP: {
  skip "Set APP_TEST for the tests to run fully",
    3 if !$ENV{APP_TEST};

my $projectList = $Git->list_projects;
ok( scalar @{$projectList} == 2, 'list_projects returns an array with the correct number of members' );
ok( $projectList->[0]->{name} eq 'bare.git', 'list_projects has correct name for "bare.git" repo' );
ok( $projectList->[1]->{name} eq 'working/.git', 'list_projects has correct name for "working" repo' );

use Data::Dumper;
warn( Dumper($projectList) );

} # Close APP_TEST skip
