#!/usr/bin/env perl

# This script installs an initial local::lib into your application directory
# named local-lib5, which automatically turns on local::lib support by default.

# Needs to be run as script/bootstrap.pl

# Will then install Module::Install, and all of your dependencies into
# the local lib directory created.

use strict;
use warnings;

use FindBin;

my $basedir = -r "$FindBin::Bin/Makefile.PL"
              ? $FindBin::Bin
              : -r "$FindBin::Bin/../Makefile.PL"
                ? "$FindBin::Bin/.."
                : '';

system "$basedir/script/cpanm" => qw(-L local-lib5 local::lib Module::Install YAML Module::Install::Catalyst);
system "$basedir/script/cpanm" => qw(-L local-lib5 --force --installdeps .);
