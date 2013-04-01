#!/usr/bin/perl

use strict;

use FindBin;
BEGIN {
    my $env = "$FindBin::Bin/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use Gitalist;

my $app = Gitalist->apply_default_middlewares(Gitalist->psgi_app);
$app;
