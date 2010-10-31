use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage 1.04;

pod_coverage_ok($_,  {
    also_private => [qw/
        BUILD
        BUILDARGS
        build_per_context_instance
    /],
}) for all_modules('lib');
