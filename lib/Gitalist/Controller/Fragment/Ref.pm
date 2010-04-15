package Gitalist::Controller::Fragment::Ref;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }
with qw/
    Gitalist::URIStructure::Ref
    Gitalist::URIStructure::Fragment::WithLog
/;

use File::Type::WebImages ();

sub base : Chained('/fragment/repository/find') PathPart('') CaptureArgs(0) {}

sub _diff {
    my ($self, $c) = @_;
    my $commit = $c->stash->{Commit};
    my %filename = $c->stash->{filename} ? (filename => $c->stash->{filename}) : ();
    my($tree, $patch) = $c->stash->{Repository}->diff(
        commit => $commit,
        parent => $c->stash->{parent},
        patch  => 1,
        %filename,
    );
    $c->stash(
      diff_tree => $tree,
      diff      => $patch,
      # XXX Hack hack hack, see View::SyntaxHighlight
      blobs     => [map $_->{diff}, @$patch],
      %filename,
    );
}

after diff_fancy => sub {
    my ($self, $c) = @_;
    $self->_diff($c);
    $c->forward('Model::ContentMangler');
};

after diff_plain => sub {
    my ($self, $c) = @_;
    $self->_diff($c);
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
    );
};

after blame => sub {
    my($self, $c) = @_;

    my $repository = $c->stash->{Repository};
                                                      # WTF?
    my $blame = $c->stash->{Commit}->blame($c->stash->{filename}, $c->stash->{Commit}->sha1);
    $c->stash(
        blame    => $blame,
        blob     => join("\n", map $_->{line}, @$blame),
    );

    $c->forward('Model::ContentMangler')
        unless $c->stash->{no_wrapper};
};

=head2 blob

The blob action i.e the contents of a file.

=cut

after blob => sub {
    my ( $self, $c ) = @_;
    $c->stash(
        is_image  => File::Type::WebImages::mime_type($c->stash->{blob}),
        is_binary => Gitalist::Utils::is_binary($c->stash->{blob}),
    );

    $c->forward('Model::ContentMangler')
        unless $c->stash->{no_wrapper};
};

after history => sub {
    my ($self, $c) = @_;
    my $repository  = $c->stash->{Repository};
    my $filename    = $c->stash->{filename};

    my %logargs = (
       sha1   => $c->stash->{Commit}->sha1,
       count  => 25, #Gitalist->config->{paging}{log} || 25,
       ($filename ? (file => $filename) : ())
    );

    my $file = $repository->get_object(
        $repository->hash_by_path(
            $repository->head_hash,
            $filename
        )
    );

    my $page = $c->req->param('pg') || 0;
    $logargs{skip} = $c->req->param('pg') * $logargs{count}
        if $c->req->param('pg');

    $c->stash(
       log_lines => [$repository->list_revs(%logargs)],
       refs      => $repository->references,
       filename  => $filename,
       filetype  => $file->type,
    );
};

__PACKAGE__->meta->make_immutable;
