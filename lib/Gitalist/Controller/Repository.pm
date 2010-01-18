package Gitalist::Controller::Repository;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }
with 'Gitalist::URIStructure::Repository';

sub base : Chained('/base') PathPart('') CaptureArgs(0) {}

__PACKAGE__->meta->make_immutable;
