#!/usr/bin/env perl
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

use Test::Pod 1.14;

all_pod_files_ok( all_pod_files('lib') );
