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
use Path::Class::Dir;
use Path::Class qw' file dir ';

BEGIN { use_ok 'Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive' }

my $repo_dir = dir( "$Bin/lib/repositories" );
my $repo = Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive->new( repo_dir => $repo_dir );
isa_ok($repo, 'Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive');

is($repo->repo_dir, $repo_dir, "repo->repo_dir is correct" );

# 'bare.git' is a bare git repository in the repository dir

my $repository_list = $repo->repositories;
is( scalar @{$repository_list}, 7, '->repositories is an array with the correct number of members' );
isa_ok($repository_list->[0], 'Gitalist::Git::Repository');
my @expected_names = sort map file($_)->stringify, qw(bare.git recursive/barerecursive.git nodescription repo1 recursive/other_bare.git recursive/goingdeeper/scratch.git recursive/goingdeeper2/scratch.git);
my @sorted_names   = sort map { $_->{name} } @{$repository_list};
is_deeply( \@sorted_names, \@expected_names , 'Repositories are correctly loaded' );

my $get_repo_from_native_name = sub { $repo->get_repository( dir( $_[0] )->stringify ) };

dies_ok {
  my $repository = $get_repo_from_native_name->( "NoSuchRepository" );
} 'throws exception for invalid repository';

dies_ok {
  my $repository = $repo->get_repository;
} 'throws exception for no repository';

dies_ok {
  my $repository = $get_repo_from_native_name->( '../../../' );
} 'Relative directory not contained within repo_dir';

my $repository = $get_repo_from_native_name->( "repo1" );
isa_ok($repository, 'Gitalist::Git::Repository');

$repository = $get_repo_from_native_name->( "recursive/goingdeeper/scratch.git" );
isa_ok($repository, 'Gitalist::Git::Repository');
cmp_ok($repository->description, 'eq', 'goingdeeper/scratch.git repo', 'Got the right repo');

$repository = $get_repo_from_native_name->( "recursive/goingdeeper2/scratch.git" );
isa_ok($repository, 'Gitalist::Git::Repository');
cmp_ok($repository->description, 'eq', 'goingdeeper2/scratch.git repo', 'Got the right repo');


# check for bug where get_repository blew up if repo_dir
# was a relative path
lives_ok {
  my $repo2_dir = "$Bin/lib/../lib/repositories";
  my $repo2 = Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive->new( repo_dir => $repo2_dir );

  my $repo2_proj = $repo2->get_repository( dir( "repo1" )->stringify );
} 'relative repo_dir properly handled';
