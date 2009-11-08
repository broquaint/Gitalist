use MooseX::Declare;

class Gitalist::Git::Repo with Gitalist::Git::HasUtils {
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Path::Class qw/Dir/;
    use MooseX::Types::Moose qw/ArrayRef/;
    use aliased 'Gitalist::Git::Project';

    # FIXME - this is nasty as we build the Git::Utils thing without a project name
    #         should refactor or something?
    method _build__util {
        Gitalist::Git::Util->new();
    }

    has repo_dir => (
        isa => Dir,
        is => 'ro',
        required => 1,
        coerce => 1,
    );

    method project (NonEmptySimpleStr $project) {
        return Project->new(
            name => $project,
            path => $self->repo_dir->subdir($project),
        );
    }


=head2 _is_git_repo

Determine whether a given directory (as a L<Path::Class::Dir> object) is a
C<git> repo.

=cut

    method _is_git_repo ($dir) {
        return -f $dir->file('HEAD') || -f $dir->file('.git', 'HEAD');
    }

=head2 list_projects

For the C<repo_dir> specified in the config return an array of projects where
each item will contain the contents of L</project_info>.

=cut

    has projects => (
        isa => ArrayRef['Gitalist::Git::Project'],
        reader => 'list_projects',
        lazy_build => 1,
    );

    method _build_projects {
        my $base = $self->repo_dir;
        my $dh = $base->open || die "Could not open $base";
        my @ret;
        while (my $file = $dh->read) {
            next if $file =~ /^.{1,2}$/;

            my $obj = $base->subdir($file);
            next unless -d $obj;
            next unless $self->_is_git_repo($obj);

            push @ret, $self->project($file);
        }

        return [sort { $a->name cmp $b->name } @ret];
    }
}                               # end class
