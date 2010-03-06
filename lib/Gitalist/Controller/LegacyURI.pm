package Gitalist::Controller::LegacyURI;
use Moose;
use Moose::Autobox;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }

my %LEGACY_DISPATCH = (
    opml                     => sub { '/opml/opml' },
    project_index            => sub { '/legacyuri/project_index' },
    '(?:summary|heads|tags)' => sub {
        my($c, $action, $repos) = @_;
        return "/repository/$action", [$repos];
    },
    blob => sub {
        my($c, $action, $repos) = @_;
        my $ref = $c->req->param('hb') || $c->req->param('h');
        return '/ref/blob', [$repos, $ref], $c->req->param('f');
    },
    blob_plain               => sub {
        my($c, $action, $repos) =  @_;
        my $ref = $c->req->param('hb') || $c->req->param('h');
        return '/ref/raw', [$repos, $ref], $c->req->param('f');
    },
);

sub _legacy_uri {
    my($self, $c, $repos, $action) = @_;

    return
        unless $action;

    my @result  = grep { $action =~ /^$_$/ } keys %LEGACY_DISPATCH;
    die "Matched too many actions for '$a' - @result"
        if @result > 1;

    return $LEGACY_DISPATCH{$result[0]}->($c, $action, $repos)
        if $result[0];
}

sub handler : Chained('/base') PathPart('legacy') Args() {
    my ( $self, $c, $repos ) = @_;

    my ($action, $captures, @args) = $self->_legacy_uri($c, $repos, $c->req->param('a'));

    die("Not supported")
        unless $action;

    $c->res->redirect($c->uri_for_action($action, $captures || [], @args));
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
