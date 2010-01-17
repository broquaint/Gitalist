package Gitalist::Controller::Fragment::Repository;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'Gitalist::URIStructure::Repository';

sub base : Chained('/fragment/base') PathPart('') CaptureArgs(0) {}

after shortlog => sub {
    my ($self, $c) = @_;
    my $repository  = $c->stash->{Repository};
#    my $commit   =  $self->_get_object($c, $c->req->param('hb'));
#    my $filename = $c->req->param('f') || '';

    my %logargs = (
       sha1   => $repository->head_hash, # $commit->sha1
       count  => 25, #Gitalist->config->{paging}{log} || 25,
#       ($filename ? (file => $filename) : ())
    );

    my $page = $c->req->param('pg') || 0;
    $logargs{skip} = $c->req->param('pg') * $logargs{count}
        if $c->req->param('pg');
    $c->stash(
#       commit    => $commit,
       log_lines => [$repository->list_revs(%logargs)],
#       refs      => $repository->references,
#       page      => $page,
#       filename  => $filename,
    );
};

after heads => sub {
    my ($self, $c) = @_;
    $c->stash(
        heads => $c->stash->{Repository}->heads,
    );
};

=head2 tags

The current list of tags in the repo.

=cut

after tags => sub {
  my ( $self, $c ) = @_;
  $c->stash(
    tags   => $c->stash->{Repository}->tags,
  );
};

__PACKAGE__->meta->make_immutable;
