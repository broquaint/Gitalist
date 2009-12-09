#!/usr/bin/env perl
use FindBin;
BEGIN { do "$FindBin::Bin/env" or die $@ }

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('Gitalist','Test');

1;

=head1 NAME

gitalist_test.pl - Catalyst Test

=head1 SYNOPSIS

gitalist_test.pl [options] uri

 Options:
   -help    display this help and exits

 Examples:
   gitalist_test.pl http://localhost/some_action
   gitalist_test.pl /some_action

 See also:
   perldoc Catalyst::Manual
   perldoc Catalyst::Manual::Intro

=head1 DESCRIPTION

Run a Catalyst action from the command line.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
