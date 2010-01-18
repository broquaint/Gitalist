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

__PACKAGE__->meta->make_immutable;
