use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;

use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Util' }

use Path::Class;
my $proj = Gitalist::Git::Util->new(
    gitdir => dir("$Bin/../lib/repositories/repo1"),
);
isa_ok($proj, 'Gitalist::Git::Util');

like( $proj->_git, qr#/git$#, 'git binary found');
isa_ok($proj->_gpp, 'Git::PurePerl', 'gpp instance created');
like($proj->gitdir, qr#/repositories/repo1#, 'repository path is set');



