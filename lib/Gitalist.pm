package Gitalist;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

extends 'Catalyst';

use Catalyst qw/-Debug
                ConfigLoader
                Static::Simple
				StackTrace/;
our $VERSION = '0.01';

# Bring in the libified gitweb.cgi.
use gitweb;

before 'setup' => sub {
    my $app = shift;
    $app->config('Model::Git' => { repo_dir => $app->config('repo_dir') });
};

__PACKAGE__->config(
	name => 'Gitalist',
	default_view => 'Default',
);

# Start the application
__PACKAGE__->setup();

=head1 NAME

Gitalist - Catalyst based application

=head1 SYNOPSIS

    script/gitalist_server.pl

=head1 DESCRIPTION

[enter your description here]

=head1 SEE ALSO

L<Gitalist::Controller::Root>, L<Catalyst>

=head1 AUTHORS AND COPYRIGHT

  Catalyst application:
    (C) 2009 Venda Ltd and Dan Brook <dbrook@venda.com>

  Original gitweb.cgi from which this was derived:
    (C) 2005-2006, Kay Sievers <kay.sievers@vrfy.org>
    (C) 2005, Christian Gierke

=head1 LICENSE

FIXME - Is this going to be GPLv2 as per gitweb? If so this is broken..

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
