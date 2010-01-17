package Gitalist::Controller::Fragment;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub base : Chained('/root') PathPart('fragment') CaptureArgs(0) {}

__PACKAGE__->meta->make_immutable;
