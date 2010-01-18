package Gitalist::Controller::Commit;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }
with 'Gitalist::URIStructure::Commit';

sub base : Chained('/repository/find') PathPart('') CaptureArgs(0) {}

__PACKAGE__->meta->make_immutable;
