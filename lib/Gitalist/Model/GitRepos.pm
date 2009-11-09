package Gitalist::Model::GitRepos;

use Moose;
use Gitalist::Git::Repo;
use namespace::autoclean;

sub COMPONENT {
    my ($class, $app, $config) = @_;

    Gitalist::Git::Repo->new($config);
}

__PACKAGE__->meta->make_immutable;
