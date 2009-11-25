#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use Test::Pod::Coverage 1.04;

all_pod_coverage_ok({
    also_private => [qw/
        BUILD
        BUILDARGS
        build_per_context_instance
    /],
});
