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

our $VERSION = '0.000003';
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

    script/gitalist_server.pl --repo_dir /home/me/code/git

=head1 INSTALL

As Gitalist follows the usual Perl module format the usual approach
for installation should work e.g.

  perl Makefile.PL
  make
  make test
  make install

or

  cpan -i Gitalist

You can also check gitalist out from git and run it, in this case you'll additionally
need the author modules, but no configuration will be needed as it will default to looking
for repositories the directory above the checkout.

=head1 DESCRIPTION

Gitalist is a web frontend for git repositories based on gitweb.cgi
and backed by Catalyst.

=head2 History

This project started off as an attempt to port gitweb.cgi to a
Catalyst app in a piecemeal fashion. As it turns out, thanks largely
to Florian Ragwitz's earlier effort, it was easier to use gitweb.cgi
as a template for building a new Catalyst application.

=head1 CONFIGURATION

Gitalist can be supplied with a config file by setting the C<< GITALIST_CONFIG >>
environment variable to point to a configuration file.

A default configuration is installed along with gitalist, which is complete except
for a repository directory. You can get a copy of this configuration by running:

  cp `perl -Ilib -MGitalist -e'print Gitalist->path_to("gitalist.conf")'` gitalist.conf

adding a repos_dir path and then setting C<< GITALIST_CONFIG >>.

Alternatively, if you only want to set a repository directory and are otherwise happy with
the default configuration, then you can set the C<< GITALIST_REPOS_DIR >> environment
variable, or pass the C<< --repos_dir >> flag to any of the scripts.

The C<< GITALIST_REPOS_DIR >> environment variable will override the repository directory set
in configuration, and will itself be overridden by he C<< --repos_dir >> flag.

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
