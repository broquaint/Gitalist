package Gitalist::Model::GitRepos;

use Moose;
use Gitalist::Git::Repo;
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
    isa => $repo_dir_t,
    is => 'ro',
    lazy_build => 1
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
    $self->repo_dir; # Explode loudly at app startup time if there is no repos
                     # dir, rather than on first hit
};

sub build_per_context_instance {
    my ($self, $app) = @_;

    Gitalist::Git::Repo->new(repo_dir => $self->repo_dir);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
