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

BEGIN { use_ok 'Gitalist::Git::CollectionOfRepositories::FromDirectory::WhiteList' }

my $repo_dir = "$Bin/lib/repositories";
my $repo     = Gitalist::Git::CollectionOfRepositories::FromDirectory::WhiteList->new(
   repo_dir  => $repo_dir,
   whitelist => "$repo_dir/projects.list",
);
isa_ok($repo, 'Gitalist::Git::CollectionOfRepositories::FromDirectory::WhiteList');

my @repos = @{$repo->repositories};
is(scalar @repos, 2, 'Only 2 repos found' );
is($repos[0]->name, 'bare.git', 'Found bare.git');
is($repos[1]->name, 'repo1', 'Found repo1');
