package Gitalist::Controller::Repository;

use Moose;
use Moose::Autobox;
use Try::Tiny qw/try catch/;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/root') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(_do_not_mangle_uri_for => 1);
}

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $repository) = @_;
    try {
        $c->stash(Repository => $c->model()->get_repository($repository));
    }
    catch {
        $c->detach('/error_404');
    };
}

sub summary : Chained('find') PathPart('') Args(0) {}

sub shortlog : Chained('find') Args(0) {
    my ($self, $c) = @_;
    $c->stash(no_wrapper => 1);
    $c->forward('/shortlog');
}

sub log : Chained('find') Args(0) {
    my ($self, $c) = @_;
    $c->stash(template => 'log.tt2');
    $c->forward('/log');
}

__PACKAGE__->meta->make_immutable;
