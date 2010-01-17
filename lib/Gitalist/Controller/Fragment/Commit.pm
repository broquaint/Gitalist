package Gitalist::Controller::Fragment::Commit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'Gitalist::URIStructure::Commit';

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

    $c->forward('View::SyntaxHighlight')
      unless $c->stash->{plain};
};

__PACKAGE__->meta->make_immutable;
