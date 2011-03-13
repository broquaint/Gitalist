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

our $VERSION = '0.003001';
$VERSION = eval $VERSION;

__PACKAGE__->config(
    name => 'Gitalist',
    default_view => 'Default',
    default_model => 'CollectionOfRepos',
    use_request_uri_for_path => 1,
    disable_component_resolution_regex_fallback => 1,
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

sub uri_with {
  my ($self, @args) = @_;
  my $uri = $self->request->uri_with(@args);
  # Wow this awful.
  $uri =~ s[/fragment\b][];
  return $uri;  
}

1;

__END__

=encoding UTF-8

=head1 NAME

Gitalist - A modern git web viewer

=head1 SYNOPSIS

    perl script/gitalist_server.pl --repo_dir /home/me/code/git

=head1 INSTALL

As Gitalist follows the usual Perl module format the usual approach
for installation should work, e.g.:

    perl Makefile.PL
    make
    make test
    make install

or

    cpan -i Gitalist

You can also L<check Gitalist out from its git repository|/"GETTING GITALIST">
and run it, in this case you'll additionally need the author modules,
but no configuration will be needed as it will default to looking
for repositories the directory above the checkout.

=head1 DESCRIPTION

Gitalist is a web frontend for git repositories based on
L<gitweb.cgi|https://git.wiki.kernel.org/index.php/Gitweb> and backed by
L<Catalyst>.

=head2 History

This project started off as an attempt to port I<gitweb.cgi> to a
Catalyst app in a piecemeal fashion. As it turns out, thanks largely
to Florian Ragwitz's earlier effort, it was easier to use I<gitweb.cgi>
as a template for building a new Catalyst application.

=head1 GETTING GITALIST

You can install Gitalist from CPAN in the usual way:

    cpan -i Gitalist

Alternatively, you can get Gitalist using git.

The canonical repository for the master branch is:

    git://git.shadowcat.co.uk/catagits/Gitalist.git

Gitalist is also mirrored to GitHub at L<https://github.com/broquaint/Gitalist>,
and a number of people have active forks
with branches and/or new features in the master branch.

=head1 BOOTSTRAPPING

As of C<0.002001> Gitalist can now be bootstrapped to run out of its
own directory by installing its prerequisites locally with the help of
L<local::lib>. So instead of installing the prerequisites to the
system path with CPAN they are installed under the Gitalist directory.

To do this clone Gitalist from the L<Shadowcat repository mentioned
above|/"GETTING GITALIST"> or grab a snapshot from broquaint's GitHub repository:

    https://github.com/broquaint/Gitalist/downloads

With the source acquired and unpacked run the following from within the
Gitalist directory:

    perl script/bootstrap.pl

This will install the necessary modules for the build process which in
turn installs the prerequisites locally.

B<NB:> The relevant bootstrap scripts aren't available in the CPAN dist
as the bootstrap scripts should not be installed.

=head1 INITIAL CONFIGURATION

Gitalist is configured using L<Catalyst::Plugin::Configloader>. The supplied sample
configuration is in L<Config::General> format, however it is possible to configure
Gitalist using other config file formats (such as YAML) if you prefer.

=head2 WHEN CHECKING GITALIST OUT OF GIT

Gitalist from git includes a minimal C<gitalist_local.conf>, which sets the repository
directory to one directory higher than the Gitalist repository.

This means that if you check Gitalist out next to your other git checkouts, then starting
the demo server needs no parameters at all:

    Gitalist [master]$ perl script/gitalist_server.pl
    You can connect to your server at http://localhost:3000

=head2 FOR CPAN INSTALLS

Gitalist can be supplied with a config file by setting the C<< GITALIST_CONFIG >>
environment variable to point to a configuration file.

If you install Gitalist from CPAN, a default configuration is installed along with gitalist,
which is complete except for a repository directory. You can get a copy of this configuration
by running:

  cp `perl -Ilib -MGitalist -e'print Gitalist->path_to("gitalist.conf")'` gitalist.conf

You can then edit this configuration, adding a C<repo_dir> path and customising
other settings as desired.

You can then start the Gitalist demo server by setting C<< GITALIST_CONFIG >>. For example:

    GITALIST_CONFIG=/usr/local/etc/gitalist.conf gitalist_server.pl

Alternatively, if you only want to set a repository directory and are otherwise happy with
the default configuration, then you can set the C<< GITALIST_REPO_DIR >> environment
variable, or pass the C<< --repo_dir >> flag to any of the scripts.

    GITALIST_REPO_DIR=/home/myuser/code/git gitalist_server.pl
    gitalist_server.pl --repo_dir home/myuser/code/git

The C<< GITALIST_REPO_DIR >> environment variable will override the repository directory set
in configuration, and will itself be overridden by he C<< --repo_dir >> flag.

=head1 RUNNING

Once you have followed the instructions above to install and configure Gitalist, you may want
to run it in a more production facing environment than using the single threaded developement
server.

The recommended deployment method for Gitalist is FastCGI, although Gitalist can also be run
under L<mod_perl|https://perl.apache.org/> or as pure Perl with L<Catalyst::Engine::PreFork>.

Assuming that you have installed Gitalist's dependencies into a L<local::lib>, and you
are running from a git checkout, adding a trivial FCGI script as C<script/gitalist.fcgi>
(this file is specifically in C<.gitignore> so you can have your own copy):

    #!/bin/sh
    exec /home/t0m/public_html/Gitalist/script/gitalist_fastcgi.pl

This example can be seen live here:

    http://example.gitalist.com

=head1 CONFIGURATION

The Gitalist config is loaded with L<Catalyst::Plugin::ConfigLoader>
and the available config options are:

=head2 Model::CollectionOfRepos

=over

=item git

Path to the C<git> binary.

=item repo_dir

A directory containing the directories to show.

=item repos

A list of directories containing repositories to show.

=item search_recursively

A boolean indicating whether to always search recursively for
repositories within C<repo_dir>.

=item whitelist

Path a file containing a list of repositories that can be shown. Each
line in the file will represent the name of a repo to show e.g

  Gitalist
  some-bare-repo.git

This is compatible with C<gitweb>'s C<projects.list>.

=item export_ok

If provided every must contain a file of the same name to be
visible. This is similar to C<gitweb>'s functionality.

=back

=head2 paging

=over

=item log

The number of commits to show in the summary, shortlog and longlog views.

=back

=head2 FASTCGI

Running Gitalist in FastCGI mode requires a webserver with FastCGI
support (such as apache with L<mod_fcgi|http://www.fastcgi.com/drupal/node/3>
or L<mod_fcgid|https://httpd.apache.org/mod_fcgid/>). Below is a sample
configuration using Apache2 with mod_fcgid in a dynamic configuration
(as opposed to static or standalone mode). More information on these modes and
their configuration can be found at L<Catalyst::Engine::FastCGI/"Standalone server mode">.

In Apache's F<mime.conf>, add C<AddHandler fcgid-script .fcgi>
(or C<AddHandler fastcgi-script .fcgi> for mod_fcgi).

And a quick VirtualHost configuration:

    <VirtualHost *:80>
        ServerName gitalist.yourdomain.com
        DocumentRoot /path/to/gitalist.fcgi
        <Directory "/path/to/gitalist.fcgi">
            AllowOverride all
            Options +ExecCGI -MultiViews +SymLinksIfOwnerMatch
            Order allow,deny
            Allow from all
        </Directory>

        # Tell Apache this is a FastCGI application
        <Files gitalist.fcgi>
            #change the below to fastcgi-script if using mod_fcgi
            SetHandler fcgid-script
        </Files>
    </VirtualHost>

Now to access your Gitalist instance, you'll go to
C<gitalist.yourdomain.com/gitalist.fcgi/> (B<do not forget that trailing> C</>).
If you'd like a different URL, of course, you'll likely want to use
L<mod_rewrite|https://httpd.apache.org/docs/mod/mod_rewrite.html> or equivalent.

If you find the need to do some troubleshooting, you can call
C<http://url_to_gitalist.fcgi?dump_info=1> and/or add export C<GITALIST_DEBUG=1>
to the top of your F<gitalist.fcgi> file (just below the shebang line).

Also, note that Apache will refuse C<%2F> in Gitalist URLs
unless configured otherwise. Make sure C<AllowEncodedSlashes On>
is in your F<httpd.conf> file in order for this to run smoothly.

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
    © 2009 Venda Ltd and Dan Brook <broq@cpan.org>
    © 2009, Tom Doran <bobtfish@bobtfish.net>
    © 2009, Zac Stevens <zts@cryptocracy.com>

  Original gitweb.cgi from which this was derived:
    © 2005-2006, Kay Sievers <kay.sievers@vrfy.org>
    © 2005, Christian Gierke

  Model based on http://github.com/rafl/gitweb
    © 2008, Florian Ragwitz

=head1 LICENSE

Licensed under GNU GPL v2
