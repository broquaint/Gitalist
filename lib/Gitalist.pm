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
                SubRequest
/;

our $VERSION = '0.000005';
$VERSION = eval $VERSION;

__PACKAGE__->config(
    name => 'Gitalist',
    default_view => 'Default',
    default_model => 'CollectionOfRepos',
);

__PACKAGE__->setup();

after prepare_path => sub {
    my ($ctx) = @_;
    if ($ctx->req->param('a')) {
        $ctx->request->uri->path('/legacy' . $ctx->request->uri->path);
    }
};

around uri_for => sub {
  my ($orig, $c) = (shift, shift);
  my $uri = $c->$orig(@_);
  $$uri =~ tr[&][;] if defined $uri;
  return $uri;
};

around uri_for_action => sub {
  my ($orig, $c) = (shift, shift);
  my $uri = $c->$orig(@_);
  $$uri =~ s[/fragment\b][] if defined $uri;
  return $uri;
};

sub uri_with {
  my ($self, @args) = @_;
  my $uri = $self->request->uri_with(@args);
  # Wow this awful.
  $uri =~ s[/fragment\b][];
  return $uri;  
}

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

=head1 GETTING GITALIST

You can install Gitalist from CPAN in the usual way:

    cpan -i Gitalist

Alternatively, you can get Gitalist using git.

The canonical repository for the master branch is:

    git://git.shadowcat.co.uk/catagits/Gitalist.git

Gitalist is also mirrored to github, and a number of people have active forks
with branches and/or new features in the master branch.

=head1 INITIAL CONFIGURATION

Gitalist is configured using L<Catalyst::Plugin::Configloader>. The supplied sample
configuration is in L<Config::General> format, however it is possible to configure
Gitalist using other config file formats (such as YAML) if you prefer.

=head2 WHEN CHECKING GITALIST OUT OF GIT

Gitalist from git includes a minimal C<gitalist_local.conf>, which sets the repository
directory to one directory higher than the Gitalist repository.

This means that if you check Gitalist out next to your other git checkouts, then starting
the demo server needs no parameters at all:

    Gitalist [master]$ ./script/gitalist_server.pl
    You can connect to your server at http://localhost:3000

=head2 FOR CPAN INSTALLS

Gitalist can be supplied with a config file by setting the C<< GITALIST_CONFIG >>
environment variable to point to a configuration file.

If you install Gitalist from CPAN, a default configuration is installed along with gitalist,
which is complete except for a repository directory. You can get a copy of this configuration
by running:

  cp `perl -Ilib -MGitalist -e'print Gitalist->path_to("gitalist.conf")'` gitalist.conf

You can then edit this confg, adding a repos_dir path and customising other settings as desired.

You can then start the Gitalist demo server by setting C<< GITALIST_CONFIG >>. For example:

    GITALIST_CONFIG=/usr/local/etc/gitalist.conf gitalist_server.pl

Alternatively, if you only want to set a repository directory and are otherwise happy with
the default configuration, then you can set the C<< GITALIST_REPO_DIR >> environment
variable, or pass the C<< --repos_dir >> flag to any of the scripts.

    GITALIST_REPO_DIR=/home/myuser/code/git gitalist_server.pl
    gitalist_server.pl --repos_dir home/myuser/code/git

The C<< GITALIST_REPO_DIR >> environment variable will override the repository directory set
in configuration, and will itself be overridden by he C<< --repos_dir >> flag.

=head1 RUNNING

Once you have followed the instructions above to install and configure Gitalist, you may want
to run it in a more production facing environment than using the single threaded developement
server.

The recommended deployment method for Gitalist is FastCGI, although Gitalist can also be run
under mod_perl or as pure perl with L<Catalyst::Engine::PreFork>.

Assuming that you have installed Gitalist's dependencies into a L<local::lib>, and you
are running from a git checkout, adding a trivial FCGI script as C<script/gitalist.fcgi>
(this file is specifically in C<.gitignore> so you can have your own copy):

    #!/bin/sh
    export PERL5LIB=/home/t0m/public_html/Gitalist/lib:/home/t0m/perl5/lib/perl5:$PERL5LIB
    exec /home/t0m/public_html/Gitalist/script/gitalist_fastcgi.pl

This example can be seen live here:

    http://goatse.co.uk/~bobtfish/Gitalist/script/gitalist.fcgi/

=head1 CONTRIBUTING

Patches are welcome, please feel free to fork on github and send pull requests, send patches
from git format-patch to the bug tracker, or host your own copy of gitalist somewhere and
ask us to pull from it.

=head1 SUPPORT

Gitalist has an active irc community in C<#gitalist> on irc.perl.org, please feel free to stop
by and ask questions, report bugs or installation issues or generally for a chat about where
we plan to go with the project.

=head1 SEE ALSO

L<Gitalist::Controller::Root>

L<Gitalist::Git::Repository>

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
