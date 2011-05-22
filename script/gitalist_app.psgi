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
use Plack::Builder;

Gitalist->setup_engine('PSGI');
my $app = sub { Gitalist->run(@_) };

builder { $app };
