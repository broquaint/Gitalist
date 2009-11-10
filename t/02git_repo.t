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

my $project_list = $repo->{projects};
isa_ok(@$project_list[0], 'Gitalist::Git::Project');

dies_ok {
    my $project = $repo->project('NoSuchProject');
} 'throws exception for invalid project';

dies_ok {
    my $project = $repo->project();
} 'throws exception for no project';

my $project = $repo->project('repo1');
isa_ok($project, 'Gitalist::Git::Project');
