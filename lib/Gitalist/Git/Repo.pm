use MooseX::Declare;

class Gitalist::Git::Repo {
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Path::Class qw/Dir/;
    use MooseX::Types::Moose qw/ArrayRef/;
    use aliased 'Gitalist::Git::Project';

    has repo_dir => (
        isa => Dir,
        is => 'ro',
        required => 1,
        coerce => 1,
    );

    has projects => (
        is => 'ro',
        isa => ArrayRef['Gitalist::Git::Project'],
        required => 1,
        lazy_build => 1,
    );

    method BUILD {
        # Make sure repo_dir is an absolute path so that
        # ->contains() works correctly.
        $self->repo_dir->resolve;
    }

    ## Public methods
    method get_project (NonEmptySimpleStr $name) {
        my $path = $self->repo_dir->subdir($name)->resolve;
        die "Directory traversal prohibited"
            unless $self->repo_dir->contains($path);
        die "Not a valid Project"
            unless $self->_is_git_repo($path);
        return Project->new( $path );
    }

    ## Builders
    method _build_projects {
        my $dh = $self->repo_dir->open || die "Could not open repo_dir";
        my @ret;
        while (my $dir_entry = $dh->read) {
            # try to get a project for each entry in repo_dir
             eval {
                 my $p = $self->get_project($dir_entry);
                 push @ret, $p;
            };
         }

        return [sort { $a->name cmp $b->name } @ret];
    }

    ## Private methods
    # Determine whether a given directory is a git repo.
    method _is_git_repo ($dir) {
        return -f $dir->file('HEAD') || -f $dir->file('.git', 'HEAD');
    }
}                               # end class

__END__

=head1 NAME

Gitalist::Git::Repo - Model of a repository directory

=head1 SYNOPSIS

    my $repo = Gitalist::Git::Repo->new( repo_dir => $Dir );
    my $project_list = $repo->projects;
    my $first_project = @$project_list[0];
    my $named_project = $repo->get_project('Gitalist');

=head1 DESCRIPTION

This class models a Gitalist Repo, which is a collection of
Projects (git repositories).  It is used for creating Project
objects to work with.


=head1 ATTRIBUTES

=head2 repo_dir (C<Path::Class::Dir>)

The filesystem root of the Repo.

=head2 projects

An array of all Repos found in C<repo_dir>.



=head1 METHODS

=head2 get_project (Str $name)

Returns a L<Gitalist::Git::Project> for the specified project
name.


=head1 SEE ALSO

L<Gitalist::Git::Project>


=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
