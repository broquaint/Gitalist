package Gitalist::Controller::LegacyURI;
use Moose;
use Moose::Autobox;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }

sub handler : Chained('/base') PathPart('legacy') Args() {
    my ( $self, $c ) = @_;
    my $action;
    if (my $a = $c->req->param('a')) {
        $a eq 'opml' && do { $action = '/opml/opml'; };
        $a eq 'project_index' && do { $action = '/legacyuri/project_index'; };
        $a eq 'summary' && do { $action = '/repository/summary'; };
    }
    die("Not supported") unless $action;
    $c->res->redirect($c->uri_for_action($action));
    $c->res->status(301);
}

sub project_index : Chained('/base') Args(0) {
      my ( $self, $c ) = @_;

      $c->response->content_type('text/plain');
      $c->response->body(
          join "\n", map $_->name, $c->model()->repositories->flatten
      ) or die 'No repositories found in '. $c->model->repo_dir;
}

__PACKAGE__->meta->make_immutable;
