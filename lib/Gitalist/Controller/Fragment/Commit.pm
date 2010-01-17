package Gitalist::Controller::Fragment::Commit;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }
with 'Gitalist::URIStructure::Commit';

sub base : Chained('/fragment/repository/find') PathPart('') CaptureArgs(0) {}

__PACKAGE__->meta->make_immutable;
