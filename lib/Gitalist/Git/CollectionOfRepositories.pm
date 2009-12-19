use MooseX::Declare;

role Gitalist::Git::CollectionOfRepositories {
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Moose qw/ArrayRef/;
    use Moose::Autobox;
    use aliased 'Gitalist::Git::Repository';

    has repositories => (
        is => 'ro',
        isa => ArrayRef['Gitalist::Git::Repository'],
        required => 1,
        lazy_build => 1,
    );
    method get_repository (NonEmptySimpleStr $name) {
        my $path = $self->_get_path_for_repository_name($name);
        die "Not a valid git repository."
            unless $self->_is_git_repo($path);
        return Repository->new( $path );
    }
    # Determine whether a given directory is a git repo.
    method _is_git_repo ($dir) {
        return -f $dir->file('HEAD') || -f $dir->file('.git', 'HEAD');
    }
    requires qw/
        _build_repositories
        _get_path_for_repository_name
    /;

    around _build_repositories {
        [sort { $a->name cmp $b->name } $self->$orig->flatten];
    }
}

1;
