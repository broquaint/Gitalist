use strict;
use warnings;

use Test::More;

my($ver) = `git --version`;
ok !$!;
ok $ver;
warn "Git version: $ver";

done_testing;

