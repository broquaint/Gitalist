package Gitalist::Controller::LegacyURI;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }

sub handler : Chained('/base') PathPart('legacy') Args() {
    die("Not supported");
}

__PACKAGE__->meta->make_immutable;
