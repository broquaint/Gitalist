package Gitalist::Controller::Fragment;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }

sub base : Chained('/base') PathPart('fragment') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->stash(no_wrapper => 1);
}

sub collectionofrepositories : Chained('base') Args(0) {
    my ($self, $c) = @_;
    my @list = @{ $c->model()->repositories };
    die 'No repositories found in '. $c->model->repo_dir
      unless @list;

    my $search = $c->req->param('s') || '';
    if($search) {
      @list = grep {
           index($_->name, $search) > -1
        or ( $_->description !~ /^Unnamed repository/ and index($_->description, $search) > -1 )
      } @list
    }

    $c->stash(
      repositories    => \@list,
    );
}

__PACKAGE__->meta->make_immutable;
