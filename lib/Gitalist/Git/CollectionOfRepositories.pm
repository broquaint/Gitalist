use MooseX::Declare;

role Gitalist::Git::CollectionOfRepositories
     with Gitalist::Git::Serializable
     with Gitalist::Git::CollectionOfRepositories::Role::Context {
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Moose qw/ArrayRef/;
    use Moose::Autobox;
    use aliased 'Gitalist::Git::Repository';

    requires 'debug_string';

    has repositories => (
        is         => 'ro',
        isa        => ArrayRef['Gitalist::Git::Repository'],
        required   => 1,
        lazy_build => 1,
    );

    has export_ok => (
        is => 'ro',
        isa => 'Str',
    );

    method get_repository (NonEmptySimpleStr $name) {
        my $repo = $self->_get_repo_from_name($name);
        confess("Couldn't get_repository '$name' - not a valid git repository.")
            unless $self->_is_git_repo($repo->path);
        return $repo;
    }

    # Determine whether a given directory is a git repo.
    # http://www.kernel.org/pub/software/scm/git/docs/gitrepository-layout.html
    method _is_git_repo ($dir) {
        my $has_head   = -f $dir->file('HEAD') || -f $dir->file('.git', 'HEAD');
        my $eok_file   = $self->export_ok
             or return $has_head;
        my $is_visible = $eok_file
             && (-f $dir->file($eok_file) || -f $dir->file('.git', $eok_file));

        return $has_head && $is_visible;
    }
    requires qw/
        _build_repositories
        _get_repo_from_name
    /;

    around _build_repositories {
        [sort { $a->name cmp $b->name } $self->$orig->flatten];
    }
}

1;

=head1 NAME

Gitalist::Git::CollectionOfRepositories - Interface and partial implementation of a collection of git repositories

=head1 SYNOPSIS

    package My::Example::CollectionOfRepositories;
    use Moose::Role;
    use namespace::autoclean;

    with 'Gitalist::Git::CollectionOfRepositories';

    sub _build_repositories {
        my $self = shift;
        [ $self->get_repository('Gitalist') ];
    }
    sub _get_path_for_repository_name {
        my ($self, $name) = @_;
        '/var/example/' . $name . '.git';
    }

    my $collection = My::Example::CollectionOfRepositories->new
    my $repository_list = $collection->repositories;
    my $only_repository = $repository_list->[0];
    my $named_repository = $repo->get_repository('Gitalist');

=head1 DESCRIPTION

This role provides an abstraction for a list of Repository directories.

=head1 ATTRIBUTES

=head2 repositories

An array of all L<Gitalist::Git::Repository>s.

=head1 METHODS

=head2 get_repository (Str $name)

Returns a L<Gitalist::Git::Repository> for the given name.
If C<$name> is not a valid git repository an exception will be thrown.

=head1 SEE ALSO

L<Gitalist::Git::CollectionOfRepositories::FromListOfDirectories>,
L<Gitalist::Git::CollectionOfRepositories::FromDirectory>,
L<Gitalist::Git::Repository>.

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut

