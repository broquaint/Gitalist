use MooseX::Declare;

class Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive
    with Gitalist::Git::CollectionOfRepositories {

    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Path::Class qw/Dir/;

    use Moose::Autobox;
    use List::Util 'first';

    has repo_dir => (
        isa => Dir,
        is => 'ro',
        required => 1,
        coerce => 1,
    );

    method BUILD {
      # Make sure repo_dir is an absolute path so that ->contains() works correctly.
      $self->repo_dir->resolve;
    }

    method _find_repos(Dir $dir) {
      return map {
        $self->_is_git_repo($_) ? $_ : $self->_find_repos($_)
      } grep $_->is_dir, $dir->children;
    }

    method _get_repo_from_name (NonEmptySimpleStr $name) {
      my $repo = first { $_->name eq $name } $self->repositories->flatten
        or return;
      return $repo;
    }

    method _get_repo_name (NonEmptySimpleStr $name) {
        # strip off the repo_dir part from a path
        return Path::Class::Dir->new($name)->relative($self->repo_dir)->stringify;
    }

    ## Builders
    method _build_repositories {
      return [
        map { Gitalist::Git::Repository->new($_, $self->_get_repo_name("$_")) } $self->_find_repos( $self->repo_dir )
      ];
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
