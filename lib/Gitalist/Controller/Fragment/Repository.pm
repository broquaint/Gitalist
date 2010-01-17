package Gitalist::Controller::Fragment::Repository;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'Gitalist::URIStructure::Repository';

sub base : Chained('/fragment/base') PathPart('') CaptureArgs(0) {}

after shortlog => sub {
    my ($self, $c) = @_;
    $c->forward('/shortlog');
};

after heads => sub {
    my ($self, $c) = @_;
    $c->stash(
        heads => $c->stash->{Repository}->heads,
    );
};

after log => sub {
    my ($self, $c) = @_;
    $c->stash(
        template => 'log.tt2',
    );
    $c->forward('/log');
};

__PACKAGE__->meta->make_immutable;
