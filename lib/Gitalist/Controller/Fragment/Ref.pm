package Gitalist::Controller::Fragment::Ref;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }
with qw/
    Gitalist::URIStructure::Ref
    Gitalist::URIStructure::Fragment::WithLog
/;

sub base : Chained('/fragment/repository/find') PathPart('') CaptureArgs(0) {}

after diff => sub {
    my ($self, $c) = @_;
    my $commit = $c->stash->{Commit};
    my($tree, $patch) = $c->stash->{Repository}->diff(
        commit => $commit,
        parent => $c->req->param('hp') || undef,
        patch  => 1,
    );
    $c->stash(
      diff_tree => $tree,
      diff      => $patch,
      # XXX Hack hack hack, see View::SyntaxHighlight
      blobs     => [map $_->{diff}, @$patch],
      language  => 'Diff',
    );
};

after diff_fancy => sub {
    my ($self, $c) = @_;
    $c->forward('View::SyntaxHighlight');
};

after diff_plain => sub {
    my ($self, $c) = @_;
    $c->response->content_type('text/plain; charset=utf-8');
};

after tree => sub {
    my ( $self, $c ) = @_;
    my $repository = $c->stash->{Repository};
    my $commit  = $c->stash->{Commit};
    my $tree    = $c->stash->{filename}
      ? $repository->get_object($repository->hash_by_path($commit->sha1, $c->stash->{filename}))
      : $repository->get_object($commit->tree_sha1)
    ;
    $c->stash(
        tree      => $tree,
        tree_list => [$repository->list_tree($tree->sha1)],
        path      => $c->stash->{filename}, # FIXME?
    );
};

after blame => sub {
    my($self, $c) = @_;

    my $repository = $c->stash->{Repository};
                                                      # WTF?
    my $blame = $c->stash->{Commit}->blame($c->stash->{filename}, $c->stash->{Commit}->sha1);
    $c->stash(
        blame    => $blame,
        # XXX Hack hack hack, see View::SyntaxHighlight
        language => ($c->stash->{filename} =~ /\.p[lm]$/i ? 'Perl' : ''),
        blob     => join("\n", map $_->{line}, @$blame),
    );

    $c->forward('View::SyntaxHighlight')
        unless $c->stash->{no_wrapper};
};

=head2 blob

The blob action i.e the contents of a file.

=cut

after blob => sub {
    my ( $self, $c ) = @_;
    $c->stash(
        # XXX Hack hack hack, see View::SyntaxHighlight
        language => ($c->stash->{filename} =~ /\.p[lm]$/i ? 'Perl' : ''),
    );

    $c->forward('View::SyntaxHighlight')
        unless $c->stash->{no_wrapper};
};

__PACKAGE__->meta->make_immutable;
