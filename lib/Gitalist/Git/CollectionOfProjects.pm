use MooseX::Declare;

role Gitalist::Git::CollectionOfProjects {
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Moose qw/ArrayRef/;
    use Moose::Autobox;
    use aliased 'Gitalist::Git::Project';

    has projects => (
        is => 'ro',
        isa => ArrayRef['Gitalist::Git::Project'],
        required => 1,
        lazy_build => 1,
    );
    method get_project (NonEmptySimpleStr $name) {
        my $path = $self->_get_path_for_project_name($name);
        die "Not a valid Project"
            unless $self->_is_git_repo($path);
        return Project->new( $path );
    }
    # Determine whether a given directory is a git repo.
    method _is_git_repo ($dir) {
        return -f $dir->file('HEAD') || -f $dir->file('.git', 'HEAD');
    }
    requires qw/
        _build_projects
        _get_path_for_project_name
    /;

    around _build_projects {
        [sort { $a->name cmp $b->name } $self->$orig->flatten];
    }
}

1;
