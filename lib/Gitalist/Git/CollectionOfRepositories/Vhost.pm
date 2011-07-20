use MooseX::Declare;

class Gitalist::Git::CollectionOfRepositories::Vhost
    with Gitalist::Git::CollectionOfRepositories {
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Path::Class qw/Dir/;

    has vhost_dispatch => (
        isa => HashRef,
        sa => HashRef,
        traits => ['Hash'],
        required => 1,
        handles => {
            _get_collection_name_for_vhost => 'get',
        },
    );

    has collections => (
        isa => HashRef,
        traits => ['Hash'],
        required => 1,
        handles => {
            _get_collection => 'get',
        }
    );

    has vhost => (
        is => 'ro',
        isa => Str,
        required => 1,
    );

    has chosen_collection => (
        does => 'Gitalist::Git::CollectionOfRepositories',
        handles => [qw/
            _get_repo_from_name
            _build_repositories
        /],
        default => sub {
            my $self = shift;
            $self->_get_collection($self->_get_collection_name_for_vhost($self->vhost) || $self->_get_collection_name_for_vhost('default'));
        },
        lazy => 1,
    );
}                               # end class

__END__

=head1 NAME

Gitalist::Git::CollectionOfRepositories::Vhost

=head1 SYNOPSIS

    my $repo = Gitalist::Git::CollectionOfRepositories::Vhost->new(
        vhost_dispatch => {
            "git.shadowcat.co.uk" => "foo",
            "git.moose.perl.org" => "bar",
        },
        collections => {
            foo => Gitalist::Git::CollectionOfRepositories::XXX->new(),
            bar => Gitalist::Git::CollectionOfRepositories::XXX->new,
        }
    );
    my $repository_list = $repo->repositories;
    my $first_repository = $repository_list->[0];
    my $named_repository = $repo->get_repository('Gitalist');

=head1 DESCRIPTION

=head1 SEE ALSO

L<Gitalist::Git::CollectionOfRepositories>, L<Gitalist::Git::Repository>

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
