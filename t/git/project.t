use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;

use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Project' }

use Path::Class;
my $gitdir = dir("$Bin/../lib/repositories/repo1");

my $proj = Gitalist::Git::Project->new(
    path => $gitdir,
    name => "repo1",
);
isa_ok($proj, 'Gitalist::Git::Project');
is($proj->path, $gitdir, 'repository path is set');
is($proj->name, qw/repo1/, 'repository name is set');
is($proj->description, qq/some test repository/, 'repository description loaded');
isa_ok($proj->last_change, 'DateTime', 'last_change');

is($proj->info->{name}, qw/repo1/, 'repo name in info hash');

is($proj->head_hash, qw/36c6c6708b8360d7023e8a1649c45bcf9b3bd818/, 'head_hash for HEAD is correct');

is(scalar $proj->list_tree, 2, 'expected number of entries in tree');
isa_ok(($proj->list_tree)[0], 'Gitalist::Git::Object');
warn( Dumper($proj->list_tree) );
