package Gitalist::Controller::Fragment::Repository;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }
with qw/
    Gitalist::URIStructure::Repository
    Gitalist::URIStructure::Fragment::WithLog
/;

sub base : Chained('/fragment/base') PathPart('') CaptureArgs(0) {}

after heads => sub {
    my ($self, $c) = @_;
    $c->stash(
        heads => $c->stash->{Repository}->heads,
    );
};

=encoding UTF-8

=head1 NAME

Gitalist::Controller::Fragment::Repository - Fragment::Repository module for Gitalist::Controller

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
