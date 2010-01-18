package Gitalist::Controller::Repository;
use Moose;
use XML::Atom::Feed;
use XML::Atom::Entry;
use XML::RSS;
use Sys::Hostname qw/hostname/;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }
with 'Gitalist::URIStructure::Repository';

sub base : Chained('/base') PathPart('') CaptureArgs(0) {}

=head2 search

The action for the search form.

=cut

sub search : Chained('base') Args(0) {
  my($self, $c) = @_;
  my $repository = $c->stash->{Repository};
  # Lifted from /shortlog.
  my %logargs = (
#    sha1   => $commit->sha1,
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

=head2 reflog

Expose the local reflog. This may go away.

=cut

sub reflog : Chained('base') Args(0) {
  my ( $self, $c ) = @_;
  my @log = $c->stash->{Repository}->reflog(
      '--since=yesterday'
  );

  $c->stash(
      log    => \@log,
  );
}

=head2 atom

Provides an atom feed for a given repository.

=cut

sub atom : Chained('find') Args(0) {
  my($self, $c) = @_;

  my $feed = XML::Atom::Feed->new;

  my $host = lc hostname();
  $feed->title($host . ' - ' . Gitalist->config->{name});
  $feed->updated(~~DateTime->now);

  my $repository = $c->stash->{Repository};
  my %logargs = (
      sha1   => $repository->head_hash,
      count  => Gitalist->config->{paging}{log} || 25,
  );

  my $mk_title = $c->stash->{short_cmt};
  for my $commit ($repository->list_revs(%logargs)) {
    my $entry = XML::Atom::Entry->new;
    $entry->title( $mk_title->($commit->comment) );
    $entry->id($c->uri_for_action('/commit/commit', [$repository->name, $commit->sha1]));
    # XXX FIXME Needs work ...
    $entry->content($commit->comment);
    $feed->add_entry($entry);
  }

  $c->response->body($feed->as_xml);
  $c->response->content_type('application/atom+xml');
}

=head2 rss

Provides an RSS feed for a given repository.

=cut

sub rss : Chained('find') Args(0) {
  my ($self, $c) = @_;

  my $repository = $c->stash->{Repository};

  my $rss = XML::RSS->new(version => '2.0');
  $rss->channel(
    title          => lc(Sys::Hostname::hostname()) . ' - ' . Gitalist->config->{name},
    link           => $c->uri_for('summary', {p=>$repository->name}),
    language       => 'en',
    description    => $repository->description,
    pubDate        => DateTime->now,
    lastBuildDate  => DateTime->now,
  );

  my %logargs = (
      sha1   => $repository->head_hash,
      count  => Gitalist->config->{paging}{log} || 25,
#      ($c->req->param('f') ? (file => $c->req->param('f')) : ())
  );
  my $mk_title = $c->stash->{short_cmt};
  for my $commit ($repository->list_revs(%logargs)) {
    # XXX FIXME Needs work ....
    $rss->add_item(
        title       => $mk_title->($commit->comment),
        permaLink   => $c->uri_for_action('/commit/commit', [$repository->name, $commit->sha1]),
        description => $commit->comment,
    );
  }

  $c->response->body($rss->as_string);
  $c->response->content_type('application/rss+xml');
}

__PACKAGE__->meta->make_immutable;
