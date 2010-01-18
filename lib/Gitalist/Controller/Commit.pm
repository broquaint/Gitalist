package Gitalist::Controller::Commit;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }
with 'Gitalist::URIStructure::Commit';

sub base : Chained('/repository/find') PathPart('') CaptureArgs(0) {}

sub blob_plain : Chained('find_blob') Does('FilenameArgs') Args() {
    my ($self, $c) = @_;

    $c->response->content_type('text/plain; charset=utf-8');
    $c->response->body(delete $c->stash->{blob});
}

=head2 snapshot

Provides a snapshot of a given commit.

=cut

sub snapshot : Chained('base') Args() {
    my ($self, $c, $format) = @_;
    $format ||= 'tgz';
    my @snap = $c->stash->{Repository}->snapshot(
        sha1 => $c->stash->{Commit}->sha1,
        format => $format
    );
    $c->response->status(200);
    $c->response->headers->header( 'Content-Disposition' =>
                                       "attachment; filename=$snap[0]");
    $c->response->body($snap[1]);
}

=head2 patch

A raw patch for a given commit.

=cut

sub patch : Chained('find') Args(0) {
    my ($self, $c) = @_;
    $c->detach('patches', [1]);
}

=head2 patches

The patcheset for a given commit ???

=cut

sub patches : Chained('find') Args(1) {
    my ($self, $c, $count) = @_;
    $count ||= Gitalist->config->{patches}{max};
    my $commit = $c->stash->{Commit};
    my $parent = $c->req->param('hp') || undef; # FIXME
    my $patch = $commit->get_patch( $parent, $count );
    $c->response->body($patch);
    $c->response->content_type('text/plain');
    $c->response->status(200);
}

__PACKAGE__->meta->make_immutable;
