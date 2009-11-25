package Gitalist::Model::GitRepos;

use Moose;
use Gitalist::Git::Repo;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use namespace::autoclean;

extends 'Catalyst::Model';

with 'Catalyst::Component::InstancePerContext';

has repo_dir => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    required => 1,
);

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
