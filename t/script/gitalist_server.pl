#!/usr/bin/env perl

use FindBin qw/$Bin/;
use lib "$Bin/../../lib";

BEGIN {
    $ENV{GITALIST_CONFIG} = "$Bin/../gitalist.conf";
}

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('Gitalist', 'Server');

1;

