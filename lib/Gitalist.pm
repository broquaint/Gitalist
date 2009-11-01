package Gitalist;
use Moose;
use namespace::autoclean;

use Catalyst::Runtime 5.80;

extends 'Catalyst';

use Catalyst qw/
                ConfigLoader
                Static::Simple
                StackTrace/;

use Class::C3::Adopt::NEXT -no_warn;

our $VERSION = '0.01';

# Bring in the libified gitweb.cgi.
use gitweb;

__PACKAGE__->config(
    name => 'Gitalist',
    default_view => 'Default',
);

# Start the application
__PACKAGE__->setup();

sub uri_for {
    my $p = ref $_[-1] eq 'HASH'
          ? $_[-1]
          : push(@_, {}) && $_[-1];
    $p->{p} = $_[0]->model('Git')->project;

    (my $uri = $_[0]->NEXT::uri_for(@_[1 .. $#_]))
      # Ampersand! What is this, the 90s?
      =~ s/&/;/g;
    return $uri;
}

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
