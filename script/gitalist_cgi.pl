#!/usr/bin/env perl

use FindBin;
BEGIN { do "$FindBin::Bin/env" or die $@ }

use Catalyst::ScriptRunner;
Catalyst::ScriptRunner->run('Gitalist', 'CGI');

1;

=head1 NAME

gitalist_cgi.pl - Catalyst CGI

=head1 SYNOPSIS

See L<Catalyst::Manual>

=head1 DESCRIPTION

Run a Catalyst application as a cgi script.

=head1 AUTHORS

Catalyst Contributors, see Catalyst.pm

=head1 COPYRIGHT

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

