use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More;

use Data::Dumper;

BEGIN {
    use_ok 'Gitalist::Git::Util';
    use_ok 'Gitalist::Git::Project';
}

use Path::Class;
my $gitdir = dir("$Bin/lib/repositories/repo1");

my $proj = Gitalist::Git::Project->new($gitdir);
my $util = Gitalist::Git::Util->new(
    project => $proj,
);
isa_ok($util, 'Gitalist::Git::Util');

like( $util->_git, qr#/git$#, 'git binary found');
isa_ok($util->_gpp, 'Git::PurePerl', 'gpp instance created');

done_testing;
