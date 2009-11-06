use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;

use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Repo' }

my $repo_dir = "$Bin/lib/repositories";
my $repo = Gitalist::Git::Repo->new( repo_dir => $repo_dir );
isa_ok($repo, 'Gitalist::Git::Repo');

is($repo->repo_dir, $repo_dir, "repo->repo_dir is correct" );

my $project_list = $repo->list_projects;
isa_ok(@$project_list[0], 'Gitalist::Git::Project');

my $project = $repo->project('repo1');
isa_ok($project, 'Gitalist::Git::Project');
