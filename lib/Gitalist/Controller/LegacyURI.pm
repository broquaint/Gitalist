package Gitalist::Controller::LegacyURI;
use Moose;
use Moose::Autobox;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }

sub handler : Chained('/base') PathPart('legacy') Args() {
    die("Not supported");
}

sub repository_index : Chained('/base') Args(0) {
      my ( $self, $c ) = @_;

      $c->response->content_type('text/plain');
      $c->response->body(
          join "\n", map $_->name, $c->model()->repositories->flatten
      ) or die 'No repositories found in '. $c->model->repo_dir;
}

__PACKAGE__->meta->make_immutable;
