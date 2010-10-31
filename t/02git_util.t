use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use strict;
use warnings;
use Test::More;

use Data::Dumper;

BEGIN {
    use_ok 'Gitalist::Git::Util';
    use_ok 'Gitalist::Git::Repository';
}

use Path::Class;
my $gitdir = dir("$Bin/lib/repositories/repo1");

my $proj = Gitalist::Git::Repository->new($gitdir);
my $util = Gitalist::Git::Util->new(
    repository => $proj,
);
isa_ok($util, 'Gitalist::Git::Util');

like( $util->_git, qr#/git$#, 'git binary found');
isa_ok($util->gpp, 'Git::PurePerl', 'gpp instance created');

done_testing;
