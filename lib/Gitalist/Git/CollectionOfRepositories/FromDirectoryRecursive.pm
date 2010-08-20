use MooseX::Declare;

class Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive
    with Gitalist::Git::CollectionOfRepositories {
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

    method _get_path_for_repository_name (NonEmptySimpleStr $name) {
        my $path = $self->repo_dir->subdir($name)->resolve;
        die "Directory traversal prohibited"
            unless $self->repo_dir->contains($path);
        return $path;
    }

    ## Builders
    method _build_repositories {
        my @ret;
        $self->repo_dir->recurse( 
            callback => sub {
                my ( $dir ) = @_;
                if ( $dir->is_dir ) {
                    for my $repo ( @ret ) {
                        # no need to go further if parent is git dir
                        # never have a git repo in a git repo?
                        return if ( $repo->path->contains( $dir ) );
                    }
                    eval {
                        # slight hack since get_repo expects string
                        my @list = $dir->dir_list();
                        my $p = $self->get_repository($list[$#list]);
                        push @ret, $p;
                    };
                }
                return;
            }
        );
        return \@ret;
    }
}                         # end class

__END__

=head1 NAME

Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive - Model of recursive directories containing git repositories

=head1 SYNOPSIS

    my $repo = Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive->new( repo_dir => $Dir );
    my $repository_list = $repo->repositories;
    my $first_repository = $repository_list->[0];
    my $named_repository = $repo->get_repository('Gitalist');

=head1 DESCRIPTION

This class provides a list of Repositories recursively found in the given directory.

=head1 ATTRIBUTES

=head2 repo_dir (C<Path::Class::Dir>)

The filesystem root of the C<Repo>.

=head1 SEE ALSO

L<Gitalist::Git::CollectionOfRepositories>, L<Gitalist::Git::Repository>

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
