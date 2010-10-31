use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}


use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok 'Gitalist::View::Default' }

