package Gitalist::Model::GitRepos;

use Moose;
use Gitalist::Git::Repo;
use namespace::autoclean;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext'; # Note we only need to be
                                                # InstancePerContext as we nick
                                                # the config from the other
                                                # model. Once we take over just
                                                # use ::Model::Adaptor

sub build_per_context_instance {
    my ( $self, $c ) = @_;

    return Gitalist::Git::Repo->new(
        repo_dir => $c->model('Git')->repo_dir,
    );
}

__PACKAGE__->meta->make_immutable;

