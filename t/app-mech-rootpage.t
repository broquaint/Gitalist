#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use TestGitalist;
plan 'skip_all' => 'No WWW::Mechanize' unless MECH();

MECH->get_ok('/');
ok MECH->findnodes_as_string('/html/body');

done_testing;
