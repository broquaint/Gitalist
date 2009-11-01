use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;

use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Util' }

use Path::Class;
my $gitdir = dir("$Bin/../lib/repositories/repo1");

my $proj = Gitalist::Git::Util->new(
    gitdir => $gitdir,
);
isa_ok($proj, 'Gitalist::Git::Util');

like( $proj->_git, qr#/git$#, 'git binary found');
isa_ok($proj->_gpp, 'Git::PurePerl', 'gpp instance created');
is($proj->gitdir, $gitdir, 'repository path is set');



