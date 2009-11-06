use MooseX::Declare;

class Gitalist::Git::Repo {
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use Path::Class;
    use Gitalist::Git::Project;
    has repo_dir => ( isa => NonEmptySimpleStr,
                      is => 'ro',
                      required => 1 );

=head2 _is_git_repo

Determine whether a given directory (as a L<Path::Class::Dir> object) is a
C<git> repo.

=cut

    method _is_git_repo ($dir) {
        return -f $dir->file('HEAD') || -f $dir->file('.git', 'HEAD');
    }

=head2 project_dir

The directory under which the given project will reside i.e C<.git/..>

=cut

    method project_dir ($project) {
        -f $project->file('.git', 'HEAD')
            ? $project->subdir('.git')
            : $project;
    }

=head2 list_projects

For the C<repo_dir> specified in the config return an array of projects where
each item will contain the contents of L</project_info>.

=cut

    method list_projects {
        my $base = dir($self->repo_dir);
        my @ret;
        my $dh = $base->open || die "Could not open $base";
        while (my $file = $dh->read) {
            next if $file =~ /^.{1,2}$/;

            my $obj = $base->subdir($file);
            next unless -d $obj;
            next unless $self->_is_git_repo($obj);

            # FIXME - Is resolving project_dir here sane?
            #         I think not, just pass $obj down, and
            #         resolve $project->path and $project->is_bare
            #         in BUILDARGS
            push @ret, Gitalist::Git::Project->new( name => $file,
                                     path => $self->project_dir($obj),
                                 );
        }

        return [sort { $a->{name} cmp $b->{name} } @ret];
    }

=head2 dir_from_project_name

Get the corresponding directory of a given project.

=cut

    method dir_from_project_name (Str $project) {
        return dir($self->repo_dir)->subdir($project);
    }



}                               # end class
