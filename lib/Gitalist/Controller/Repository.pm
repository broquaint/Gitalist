package Gitalist::Controller::Repository;
use Moose;
use Sys::Hostname qw/hostname/;
use DateTime::Format::Mail;
use namespace::autoclean;
BEGIN { extends 'Gitalist::Controller' }
with 'Gitalist::URIStructure::Repository';

sub base : Chained('/base') PathPart('') CaptureArgs(0) {}

=encoding UTF-8

=head1 NAME

Gitalist::Controller::Repository - Controller::Repository module for Gitalist

=head2 search

The action for the search form.

=cut

sub search : Chained('find') Args(0) {
  my($self, $c) = @_;
  my $repository = $c->stash->{Repository};
  # Lifted from /shortlog.
  my %logargs = (
    sha1   => $repository->head_hash,
#    count  => Gitalist->config->{paging}{log},
#    ($c->req->param('f') ? (file => $c->req->param('f')) : ()),
    search => {
      type   => $c->req->param('type'),
      text   => $c->req->param('text'),
      regexp => $c->req->param('regexp') || 0,
    },
  );

  $c->stash(
#      commit  => $commit,
      results => [$repository->list_revs(%logargs)],
	  # This could be added - page      => $page,
  );
}

=head2 tree

Provide a simple redirect to C</ref/tree>.

=cut

sub tree : Chained('find') Args(0) {
    my($self, $c) = @_;
    $c->res->redirect($c->uri_for_action('/ref/tree', [$c->stash->{Repository}->name, 'HEAD']));
    $c->res->status(301);
}

=head2 atom

Provides an atom feed for a given repository.

=cut

sub atom : Chained('find') Does('FilenameArgs') Args() {
    my ($self, $c) = @_;

    my $host = lc hostname();
    $c->stash(
        title => $host . ' - ' . Gitalist->config->{name},
        updated => DateTime::Format::Mail->format_datetime( DateTime->now() )
    );

    my $repository = $c->stash->{Repository};
    my %logargs = (
        sha1     => $repository->head_hash,
        count    => Gitalist->config->{paging}{log} || 25,
        ($c->stash->{filename} ? (file => $c->stash->{filename}) : ()),
    );

    my @revs;
    my $mk_title = $c->stash->{short_cmt};
    for my $commit ($repository->list_revs(%logargs)) {
        my $entry = {};
        $entry->{title} = $mk_title->($commit->comment);
        $entry->{id} = $c->uri_for_action('/ref/commit', [$repository->name, $commit->sha1]);
        # XXX FIXME Needs work ...
        $entry->{content} = $commit->comment;
        push(@revs, $entry);
    }
    $c->stash(
        Commits => \@revs,
        no_wrapper => 1,
    );
    $c->response->content_type('application/atom+xml');
}

=head2 rss

Provides an RSS feed for a given repository.

=cut

sub rss : Chained('find') Does('FilenameArgs') Args() {
  my ($self, $c) = @_;

  my $repository = $c->stash->{Repository};

  $c->stash(
    title          => lc(Sys::Hostname::hostname()) . ' - ' . Gitalist->config->{name},
    language       => 'en',
    pubDate        => DateTime::Format::Mail->format_datetime( DateTime->now() ),
    lastBuildDate  => DateTime::Format::Mail->format_datetime( DateTime->now() ),
    no_wrapper     => 1,
  );

  my %logargs = (
      sha1   => $repository->head_hash,
      count  => Gitalist->config->{paging}{log} || 25,
      ($c->stash->{filename} ? (file => $c->stash->{filename}) : ()),
  );
  my @revs;
  my $mk_title = $c->stash->{short_cmt};
  for my $commit ($repository->list_revs(%logargs)) {
    # XXX FIXME Needs work ....
    push(@revs, {
        title       => $mk_title->($commit->comment),
        permaLink   => $c->uri_for_action('/ref/commit', [$repository->name, $commit->sha1]),
        description => $commit->comment,
    });
  }
  $c->stash(Commits => \@revs);
  $c->response->content_type('application/rss+xml');
}

__PACKAGE__->meta->make_immutable;
