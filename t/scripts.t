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

use_ok('Gitalist::Script::CGI');
use_ok('Gitalist::Script::Server');
use_ok('Gitalist::Script::FastCGI');

# FIXME - Test the script role.

done_testing;

