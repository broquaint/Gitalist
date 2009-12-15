package Gitalist::Model::GitRepos;

use Moose;
use Gitalist::Git::Repo;
use Gitalist::Git::CollectionOfProjects::FromListOfDirectories;
use MooseX::Types::Moose qw/Maybe ArrayRef/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use Moose::Util::TypeConstraints;
use namespace::autoclean;

extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

my $repo_dir_t = subtype NonEmptySimpleStr,
    where { -d $_ },
    message { 'Cannot find repository dir: "' . $_ . '", please set up gitalist.conf, or set GITALIST_REPO_DIR environment or pass the --repo_dir parameter when starting the application' };

has config_repo_dir => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    init_arg => 'repo_dir',
    predicate => 'has_config_repo_dir',
);

has repo_dir => (
    isa => Maybe[$repo_dir_t],
    is => 'ro',
    lazy_build => 1
);

has repos => (
    isa => ArrayRef[$repo_dir_t],
    is => 'ro',
    default => sub { [] },
    traits => ['Array'],
    handles => {
        _repos_count => 'count',
    },
);

sub _build_repo_dir {
    my $self = shift;
    $ENV{GITALIST_REPO_DIR} ?
        $ENV{GITALIST_REPO_DIR}
      : $self->has_config_repo_dir
      ? $self->config_repo_dir
        : '';
}

after BUILD => sub {
    my $self = shift;
    # Explode loudly at app startup time if there is no list of
    # projects or repos dir, rather than on first hit
    $self->_repos_count || $self->repo_dir;
};

sub build_per_context_instance {
    my ($self, $app) = @_;
    if ($self->_repos_count) {
        Gitalist::Git::CollectionOfProjects::FromListOfDirectories->new(repos => $self->repos);
    }
    else {
        Gitalist::Git::Repo->new(repo_dir => $self->repo_dir);
    }
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
