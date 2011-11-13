use MooseX::Declare;

class Gitalist::Git::CollectionOfRepositories::FromListOfDirectories with Gitalist::Git::CollectionOfRepositories {
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Moose qw/ ArrayRef HashRef /;
    use MooseX::Types::Path::Class qw/Dir/;
    use Gitalist::Git::Types qw/ ArrayRefOfDirs /;
    use File::Basename qw/basename/;
    use Path::Class qw/dir/;
    use Moose::Autobox;

    has repos => (
        isa => ArrayRefOfDirs,
        is => 'ro',
        coerce => 1,
        required => 1,
    );
    has _repos_by_name => (
        isa => HashRef[Dir],
        is => 'ro',
        lazy_build => 1,
        traits => ['Hash'],
        handles => {
            _get_path_for_repository_name => 'get',
        },
    );

    method _build__repos_by_name {
        +{ map { basename($_) => dir($_) } $self->repos->flatten };
    }

    method _get_repo_from_name (NonEmptySimpleStr $name) {
        return Gitalist::Git::Repository->new($self->_get_path_for_repository_name($name));
    }

    ## Builders
    method _build_repositories {
        [ map { $self->get_repository(basename($_)) } $self->repos->flatten ];
    }
}                               # end class

1;

=head1 NAME

Gitalist::Git::CollectionOfRepositories::FromListOfDirectories - Model of a collection of git repositories

=head1 SYNOPSIS

    my $collection = Gitalist::Git::CollectionOfRepositories::FromListOfDirectories->new( repos => [qw/
        /path/to/repos1
        /path/to/repos2
    /] );
    my $repository_list = $collection->repositories;
    my $first_repository = $repository_list->[0];
    my $named_repository = $repo->get_repository('Gitalist');

=head1 DESCRIPTION

This class provides an abstraction for a list of Repository directories.

=head1 ATTRIBUTES

=head2 repos (C<< ArrayRef[NonEmptySimpleStr] >>)

A list of git repository directories

=head1 SEE ALSO

L<Gitalist::Git::CollectionOfRepositories>, L<Gitalist::Git::Repository>

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
