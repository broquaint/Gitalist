use MooseX::Declare;

class Gitalist::Git::CollectionOfProjects::FromDirectory
    with Gitalist::Git::CollectionOfProjects {
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Path::Class qw/Dir/;

    has repo_dir => (
        isa => Dir,
        is => 'ro',
        required => 1,
        coerce => 1,
    );

    method BUILD {
        # Make sure repo_dir is an absolute path so that
        # ->contains() works correctly.
        $self->repo_dir->resolve;
    }

    method _get_path_for_project_name (NonEmptySimpleStr $name) {
        my $path = $self->repo_dir->subdir($name)->resolve;
        die "Directory traversal prohibited"
            unless $self->repo_dir->contains($path);
        return $path;
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
        return \@ret;
    }
}                               # end class

__END__

=head1 NAME

Gitalist::Git::CollectionOfProjects::FromDirectory - Model of a repository directory

=head1 SYNOPSIS

    my $repo = Gitalist::Git::CollectionOfProjects::FromDirectory->new( repo_dir => $Dir );
    my $project_list = $repo->projects;
    my $first_project = $project_list->[0];
    my $named_project = $repo->get_project('Gitalist');

=head1 DESCRIPTION

This class models a Gitalist Repo, which is a collection of
Projects (git repositories).  It is used for creating Project
objects to work with.


=head1 ATTRIBUTES

=head2 repo_dir (C<Path::Class::Dir>)

The filesystem root of the C<Repo>.

=head2 projects

An array of all L<Gitalist::Git::Repository>s found in C<repo_dir>.



=head1 METHODS

=head2 get_project (Str $name)

Returns a L<Gitalist::Git::Repository> for the given name.
If C<$name> is not a valid git repository under C<$repo_dir>, an exception
will be thrown.



=head1 SEE ALSO

L<Gitalist::Git::Repository>


=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
