package Gitalist::Controller::Root;

use Moose;
use Moose::Autobox;
use Sys::Hostname qw/hostname/;
use XML::OPML::SimpleGen;

use Gitalist::Utils qw/ age_string /;

use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }

__PACKAGE__->config->{namespace} = '';

sub root : Chained('/') PathPart('') CaptureArgs(0) {}

sub index : Chained('base') PathPart('') Args(0) {
  my ( $self, $c ) = @_;

  my $search = $c->req->param('s') || '';

  $c->stash(
    search_text => $search,
  );
}

=head2 search_help

Provides some help for the search form.

=cut

sub search_help : Chained('base') Args(0) {}

sub opml : Chained('base') Args(0) {
  my($self, $c) = @_;

  my $opml = XML::OPML::SimpleGen->new();

  $opml->head(title => lc(hostname()) . ' - ' . Gitalist->config->{name});

  my @list = @{ $c->model()->repositories };
  die 'No repositories found in '. $c->model->repo_dir
    unless @list;

  for my $proj ( @list ) {
    $opml->insert_outline(
      text   => $proj->name. ' - '. $proj->description,
      xmlUrl => $c->uri_for(rss => {p => $proj->name}),
    );
  }

  $c->response->body($opml->as_string);
  $c->response->content_type('application/rss');
  $c->response->status(200);
}

sub base : Chained('/root') PathPart('') CaptureArgs(0) {
  my($self, $c) = @_;

  my $git_version = `git --version`;
  chomp($git_version);
  $c->stash(
    git_version => $git_version,
    version     => $Gitalist::VERSION,

    # XXX Move these to a plugin!
    time_since => sub {
      return 'never' unless $_[0];
      return age_string(time - $_[0]->epoch);
    },
    short_cmt => sub {
      my $cmt = shift;
      my($line) = split /\n/, $cmt;
      $line =~ s/^(.{70,80}\b).*/$1 \x{2026}/;
      return $line;
    },
    abridged_description => sub {
        join(' ', grep { defined } (split / /, shift)[0..10]);
    },
  );
}

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;
    # Give repository views the current HEAD.
    if ($c->stash->{Repository}) {
        $c->stash->{HEAD} = $c->stash->{Repository}->head_hash;
    }
}

sub error_404 : Action {
    my ($self, $c) = @_;
    $c->response->status(404);
    $c->response->body('Page not found');
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Gitalist::Controller::Root - Root controller for the application

=head1 DESCRIPTION

This controller handles all of the root level paths for the application

=head1 METHODS

=head2 root

Root of chained actions

=head2 base

Populate the header and footer. Perhaps not the best location.

=head2 index

Provides the repository listing.

=head2 end

Attempt to render a view, if needed.

=head2 blame

=head2 error_404

=head2 history

=head2 opml

=head2 repository_index

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
