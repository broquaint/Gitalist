#!/usr/bin/env perl

# This script installs an initial local::lib into your application directory
# named local-lib5, which automatically turns on local::lib support by default.

# Needs to be run as script/bootstrap.pl

# Will then install Module::Install, and all of your dependencies into
# the local lib directory created.

use strict;
use warnings;

use lib;
use FindBin;
use CPAN;

# Do not take no for an answer.

$ENV{CATALYST_LOCAL_LIB}=1;

# Get the base paths and setup your %ENV

my $basedir;
if (-r "$FindBin::Bin/Makefile.PL") {
    $basedir = $FindBin::Bin;
}
elsif (-r "$FindBin::Bin/../Makefile.PL") {
    $basedir = "$FindBin::Bin/..";
}

$basedir ||= '';
my $target = "$basedir/local-lib5";
my $lib = "$target/lib/perl5";

# Start installing stuff in the target dir
$ENV{PERL_MM_OPT} = "INSTALL_BASE=$target";
$ENV{PERL_MM_USE_DEFAULT} = "1";
# And allow dependency checks to find it
lib->import("$target/lib/perl5");

# Deal with the weird case that cpan has never been run before and
# cpan wants to create a .cpan directory in /root or somewhere you
# can't access

local %CPAN::Config;
require CPAN::HandleConfig;
CPAN::HandleConfig->load();
$CPAN::Config->{prefs_dir} = "~/.cpan/prefs";

force(qw/install local::lib/);

require local::lib; # Turn local::lib on
local::lib->import( $target );

# Become fully self contained
$ENV{PERL5LIB} = ""; # If we used a local::lib to bootstrap, this kills it.

# Sorry kane ;)
$ENV{PERL_AUTOINSTALL_PREFER_CPAN}=1;
$ENV{PERL_MM_OPT} .= " INSTALLMAN1DIR=none INSTALLMAN3DIR=none";

local::lib->import( '--self-contained', $target );

# Force a re-install of local::lib here to get the dependencies for local::lib
# It requires things which ensure we have an unfucked toolchain :)
force(qw/install local::lib/);

# Install the base modules
install('Module::Install');
install('YAML');
install('CPAN');
install('Module::Install::Catalyst');

print "local::lib setup, type perl Makefile.PL && make installdeps to install dependencies";

