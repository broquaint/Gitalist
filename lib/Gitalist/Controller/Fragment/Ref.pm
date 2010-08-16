package Gitalist::Controller::Fragment::Ref;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }
with qw/
    Gitalist::URIStructure::Ref
    Gitalist::URIStructure::Fragment::WithLog
/;

use File::Type::WebImages ();
use JSON::XS qw(encode_json);

sub base : Chained('/fragment/repository/find') PathPart('') CaptureArgs(0) {}

sub _diff {
    my ($self, $c) = @_;
    my %diff_args = ( patch => 1 );
    foreach my $arg qw/filename parent/ {
        if (defined $c->stash->{$arg}) {
            $diff_args{$arg} = $c->stash->{$arg};
        };
    };
    my ($tree, $patch) = $c->stash->{Commit}->diff(
        %diff_args,
    );
    $c->stash(
      diff_tree => $tree,
      diff      => $patch,
      # XXX Hack hack hack, see View::SyntaxHighlight
      blobs     => [map $_->{diff}, @$patch],
      %diff_args,
    );
}

after diff_fancy => sub {
    my ($self, $c) = @_;
    $self->_diff($c);
    $c->forward('Model::ContentMangler');
};

after diff_plain => sub {
    my ($self, $c) = @_;
    $self->_diff($c);
};

after tree => sub {
    my ( $self, $c ) = @_;
    my $repository = $c->stash->{Repository};
    my $commit  = $c->stash->{Commit};
    my $tree_obj    = $c->stash->{filename}
      ? $commit->sha_by_path($c->stash->{filename})
      : $commit->tree->[0]
    ;
    $c->stash(
        tree      => $tree_obj,
        tree_list => $tree_obj->tree,
    );
};

after blame => sub {
    my($self, $c) = @_;

    my $repository = $c->stash->{Repository};
                                                      # WTF?
    my $blame = $c->stash->{Commit}->blame($c->stash->{filename}, $c->stash->{Commit}->sha1);
    $c->stash(
        blame    => $blame,
        blob     => join("\n", map $_->{line}, @$blame),
    );

    $c->forward('Model::ContentMangler');
};

=head2 blob

The blob action i.e the contents of a file.

=cut

after blob => sub {
    my ( $self, $c ) = @_;
    $c->stash(
        is_image  => File::Type::WebImages::mime_type($c->stash->{blob}),
        is_binary => Gitalist::Utils::is_binary($c->stash->{blob}),
    );
    $c->forward('Model::ContentMangler');
};

after history => sub {
    my ($self, $c) = @_;
    my $repository  = $c->stash->{Repository};
    my $filename    = $c->stash->{filename};

    my %logargs = (
       sha1   => $c->stash->{Commit}->sha1,
       count  => 25, #Gitalist->config->{paging}{log} || 25,
       ($filename ? (file => $filename) : ())
    );

    my $commit = $repository->get_object('HEAD');
    my $file = $commit->sha_by_path($filename);

    my $page = $c->req->param('pg') || 0;
    $logargs{skip} = $c->req->param('pg') * $logargs{count}
        if $c->req->param('pg');

    $c->stash(
       log_lines => [$repository->list_revs(%logargs)],
       refs      => $repository->references,
       filename  => $filename,
       filetype  => $file->type,
    );
};

after file_commit_info => sub {
    my ($self, $c) = @_;

    my $repository  = $c->stash->{Repository};

    my($commit) = $repository->list_revs(
       sha1   => $c->stash->{Commit}->sha1,
       count  => 1,
       file   => $c->stash->{filename},
    );

    my $json_obj = !$commit
                 ? { }
                 : {
                     sha1    => $commit->sha1,
                     comment => $c->stash->{short_cmt}->($commit->comment),
                     age     => $c->stash->{time_since}->($commit->authored_time),
                 };

    $c->response->content_type('application/json');
    # XXX Make use of the json branch
    $c->response->body( encode_json $json_obj );
};

__PACKAGE__->meta->make_immutable;
