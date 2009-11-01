use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;

use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Project' }

use Path::Class;
my $proj = Gitalist::Git::Project->new(
    path => dir("$Bin/../lib/repositories/repo1"),
    name => "repo1",
);
isa_ok($proj, 'Gitalist::Git::Project');

like( $proj->_git, qr#/git$#, 'git binary found');
isa_ok($proj->_gpp, 'Git::PurePerl', 'gpp instance created');
like($proj->path, qr#/repositories/repo1#, 'repository path is set');
is($proj->name, qw/repo1/, 'repository name is set');
is($proj->description, qq/some test repository/, 'repository description loaded');
isa_ok($proj->last_change, 'DateTime', 'last_change');


