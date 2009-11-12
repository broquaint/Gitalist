use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;
use Test::Exception;
use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Project' }

dies_ok {
    my $proj = Gitalist::Git::Project->new();
} 'New project with no args';

use Path::Class;
my $gitdir = dir("$Bin/lib/repositories/repo1");

my $proj = Gitalist::Git::Project->new($gitdir);
isa_ok($proj, 'Gitalist::Git::Project');
is($proj->path, $gitdir, 'repository path is set');
is($proj->name, qw/repo1/, 'repository name is set');
is($proj->description, qq/some test repository/, 'repository description loaded');
isa_ok($proj->last_change, 'DateTime', 'last_change');

is($proj->info->{name}, qw/repo1/, 'repo name in info hash');

ok($proj->heads, '->heads returns stuff');
     
is($proj->head_hash, '36c6c6708b8360d7023e8a1649c45bcf9b3bd818', 'head_hash for HEAD is correct');
is($proj->head_hash('refs/heads/master'), '36c6c6708b8360d7023e8a1649c45bcf9b3bd818', 'head_hash for refs/heads/master is correct');
is($proj->head_hash('rafs/head/mister'), undef, 'head_hash for rafs/head/mister is undef');

is(scalar $proj->list_tree, 2, 'expected number of entries in tree');
isa_ok(($proj->list_tree)[1], 'Gitalist::Git::Object');

# Return an ::Object from a sha1
my $obj1 = $proj->get_object('5716ca5987cbf97d6bb54920bea6adde242d87e6');
isa_ok($obj1, 'Gitalist::Git::Object');

# Test methods that really should be called on ::Object
# This is transitional from Git.pm
my $obj = ($proj->list_tree)[1];
isa_ok($obj, 'Gitalist::Git::Object');
is($proj->get_object_mode_string($obj), '-rw-r--r--', "get_object_mode_string");
is($proj->get_object_type('5716ca5987cbf97d6bb54920bea6adde242d87e6'), 'blob', "get_object_type");
is($proj->cat_file('5716ca5987cbf97d6bb54920bea6adde242d87e6'), "bar\n", 'cat_file');
