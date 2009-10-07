#!/usr/bin/env perl
use strict;
use warnings;
use Test::More tests => 2;

BEGIN { use_ok 'Catalyst::Test', 'Gitalist' }

# Full tests are only run if the APP_TEST env var is set.
# This is needed to load the test configuration.
diag("*** SKIPPING app tests.
*** Set APP_TEST for the tests to run fully") if !$ENV{APP_TEST};
SKIP: {
  skip "Set APP_TEST for the tests to run fully",
    1 if !$ENV{APP_TEST};

ok( request('/')->is_success, 'Request should succeed' );

} # Close APP_TEST skip
