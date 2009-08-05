#!/home/dbrook/apps/bin/perl

use lib qw(
	/home/dbrook/.perl-lib
	/home/dbrook/.perl-lib/i686-linux-thread-multi
	/home/dbrook/.perl/lib/perl5/i686-linux-thread-multi
);

BEGIN { $ENV{CATALYST_ENGINE} ||= 'CGI' }

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../lib";
use Gitalist;

Gitalist->run;

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
