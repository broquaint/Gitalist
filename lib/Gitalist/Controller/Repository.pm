package Gitalist::Controller::Repository;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'Gitalist::URIStructure::Repository';

sub base : Chained('/root') PathPart('') CaptureArgs(0) {}

__PACKAGE__->meta->make_immutable;
