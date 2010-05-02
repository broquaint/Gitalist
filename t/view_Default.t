use FindBin qw/$Bin/;
BEGIN { do "$FindBin::Bin/../script/env" or die $@ }

use strict;
use warnings;
use Test::More tests => 1;

BEGIN { use_ok 'Gitalist::View::Default' }

