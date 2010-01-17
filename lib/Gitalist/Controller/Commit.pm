package Gitalist::Controller::Commit;

use Moose;
use Moose::Autobox;
use Try::Tiny qw/try catch/;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/repository/find') PathPart('') CaptureArgs(0) {}

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $sha1part) = @_;
    $c->stash->{Commit} = $c->stash->{Repository}->get_object($sha1part)
        or $c->detach('/error404', "Couldn't find a object for '$sha1part' in XXXX!");
}

sub diff : Chained('find') Args(0) {}

sub tree : Chained('find') Args(0) {}

sub commit : Chained('find') Args(0) {}

__PACKAGE__->meta->make_immutable;
