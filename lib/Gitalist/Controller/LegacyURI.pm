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
    blobdiff                 => sub {
        my($c, $action, $repos) =  @_;
        my $ref     = $c->req->param('hb')  || $c->req->param('h');
        my $compare = $c->req->param('hbp') || $c->req->param('hp');
        return '/ref/diff_fancy', [$repos, $ref], $compare, $c->req->param('f');
    },
    blobdiff_plain           => sub {
        my($c, $action, $repos) =  @_;
        my $ref     = $c->req->param('hb')  || $c->req->param('h');
        my $compare = $c->req->param('hbp') || $c->req->param('hp');
        return '/ref/diff_plain', [$repos, $ref], $compare, $c->req->param('f');
    },
    commit                   => sub {
        my($c, $action, $repos) =  @_;
        my $ref = $c->req->param('hb') || $c->req->param('h') || 'HEAD';
        return '/ref/commit', [$repos, $ref];
    },
    # XXX These can be consolidated with the blob equivalents.
    commitdiff               => sub {
        my($c, $action, $repos) =  @_;
        my $ref     = $c->req->param('hb')  || $c->req->param('h') || 'HEAD';
        my $compare = $c->req->param('hbp') || $c->req->param('hp');
        return '/ref/diff_fancy', [$repos, $ref], $compare, $c->req->param('f');
    },
    commitdiff_plain         => sub {
        my($c, $action, $repos) =  @_;
        my $ref     = $c->req->param('hb')  || $c->req->param('h');
        my $compare = $c->req->param('hbp') || $c->req->param('hp');
        return '/ref/diff_plain', [$repos, $ref || 'HEAD'], $compare, $c->req->param('f');
    },
    history                  => sub {
        my($c, $action, $repos) =  @_;
        my $ref     = $c->req->param('hb') || $c->req->param('h') || 'HEAD';
        return '/ref/history', [$repos, $ref], $c->req->param('f');
    },
    log                      => sub {
        my($c, $action, $repos) =  @_;
        my $ref = $c->req->param('hb') || $c->req->param('h') || 'HEAD';
        return '/ref/longlog', [$repos, $ref];
    },
    patch                    => sub {
        my($c, $action, $repos) =  @_;
        my $ref = $c->req->param('hb') || $c->req->param('h') || 'HEAD';
        return '/ref/patch', [$repos, $ref];
    },
    patches                  => sub {
        my($c, $action, $repos) = @_;
        # XXX Is the arg there wrong? It's just copying G::C::R::patch.
        return '/ref/patches', [$repos, $c->req->param('h') || 'HEAD'], 1;
    },
    search_help              => sub {
        return '/search_help';
    },
    shortlog                 => sub {
        my($c, $action, $repos) =  @_;
        my $ref = $c->req->param('hb') || $c->req->param('h') || 'HEAD';
        return '/ref/shortlog', [$repos, $ref];
    },
    snapshot                 => sub {
        my($c, $action, $repos) =  @_;
        my $ref = $c->req->param('h') || 'HEAD';
        return '/ref/snapshot', [$repos, $ref], $c->req->param('sf');
    },
    tree                     => sub {
        my($c, $action, $repos) = @_;
        my $ref = $c->req->param('hb') || $c->req->param('h') || 'HEAD';
        return '/ref/tree', [$repos, $ref], $c->req->param('f');
    },
    '(?:atom|rss)'           => sub {
        my($c, $action, $repos) =  @_;
        # XXX No support for arbitrary branches or merges/nomerges option :(
        return "/repository/$action", [$repos], $c->req->param('f');
    },
    blame                    => sub {
        my($c, $action, $repos) = @_;
        my $ref = $c->req->param('hb') || $c->req->param('h');
        return '/ref/blame', [$repos, $ref], $c->req->param('f');
    },
);

sub _legacy_uri {
    my($self, $c, $repos, $action) = @_;

    return
        unless $action;

    my @result  = grep { $action =~ /^$_$/ } keys %LEGACY_DISPATCH;
    die "Matched too many actions for '$a' - @result"
        if @result > 1;

    return
        unless $result[0];

    my($real_action, $captures, @args) = $LEGACY_DISPATCH{$result[0]}->($c, $action, $repos);

    return $real_action, $captures || [], grep defined, @args;
}

sub handler : Chained('/base') PathPart('legacy') Args() {
    my ( $self, $c, $repos ) = @_;

    my ($action, $captures, @args) = $self->_legacy_uri($c, $repos, $c->req->param('a'));

    die("Not supported")
        unless $action;

    $c->res->redirect($c->uri_for_action($action, $captures, @args));
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
