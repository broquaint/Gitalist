package Gitalist;
use Moose;
BEGIN { require 5.008006; }
use Catalyst::Runtime 5.80;
use namespace::autoclean;

extends 'Catalyst';

use Catalyst qw/
                ConfigLoader
                Unicode::Encoding
                Static::Simple
                StackTrace
/;

our $VERSION = '0.000000_02';
$VERSION = eval $VERSION;

__PACKAGE__->config(
    name => 'Gitalist',
    default_view => 'Default',
    default_model => 'GitRepos',
);

__PACKAGE__->setup();

around uri_for => sub {
  my ($orig, $c) = (shift, shift);
  my $project_name = $c->stash->{'Project'} && $c->stash->{'Project'}->name;
  my $hash = ref($_[-1]) eq 'HASH' ? pop @_ : {};
  my $params = Catalyst::Utils::merge_hashes(
    { p => $hash->{p} || $project_name },
    $hash,
  );
  delete $params->{p} unless defined $params->{p} && length $params->{p};
  (my $uri = $c->$orig(@_, $params))
    =~ tr[&][;];
  return $uri;
};

1;

__END__

=head1 NAME

Gitalist - A modern git web viewer

=head1 SYNOPSIS

    script/gitalist_server.pl

=head1 INSTALL

As Gitalist follows the usual Perl module format the usual approach
for installation should work e.g

  perl Makefile.PL
  make
  make test
  make install

If you're running a git checkout of Gitalist then you'll additionally
need the author modules.

=head1 DESCRIPTION

Gitalist is a web frontend for git repositories based on gitweb.cgi
and backed by Catalyst.

=head2 History

This project started off as an attempt to port gitweb.cgi to a
Catalyst app in a piecemeal fashion. As it turns out, thanks largely
to Florian Ragwitz's earlier effort, it was easier to use gitweb.cgi
as a template for building a new Catalyst application.

=head1 SEE ALSO

L<Gitalist::Controller::Root>

L<Gitalist::Git::Project>

L<Catalyst>

=head1 AUTHORS AND COPYRIGHT

  Catalyst application:
    (C) 2009 Venda Ltd and Dan Brook <broq@cpan.org>
    (C) 2009, Tom Doran <bobtfish@bobtfish.net>
    (C) 2009, Zac Stevens <zts@cryptocracy.com>

  Original gitweb.cgi from which this was derived:
    (C) 2005-2006, Kay Sievers <kay.sievers@vrfy.org>
    (C) 2005, Christian Gierke

  Model based on http://github.com/rafl/gitweb
    (C) 2008, Florian Ragwitz

=head1 LICENSE

Licensed under GNU GPL v2

=cut
