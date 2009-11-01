use MooseX::Declare;

class Gitalist::Git::Project {
    # FIXME, use Types::Path::Class and coerce
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use DateTime;
    use Path::Class;

    has name => ( isa => NonEmptySimpleStr,
                  is => 'ro' );
    has path => ( isa => "Path::Class::Dir",
                  is => 'ro');

    has description => ( isa => NonEmptySimpleStr,
                         is => 'ro',
                         lazy_build => 1,
                     );
    has owner => ( isa => NonEmptySimpleStr,
                   is => 'ro',
                   lazy_build => 1,
               );
    has last_change => ( isa => 'DateTime',
                         is => 'ro',
                         lazy_build => 1,
                     );

    
    method _build_description {
        my $description = $self->path->file('description')->slurp;
        chomp $description;
        return $description;
    }

    method _build_owner {
        my $owner = (getpwuid $self->path->stat->uid)[6];
        $owner =~ s/,+$//;
        return $owner;
    }
    
    method _build_last_change {
        my $last_change;
        my $output = $self->run_cmd(
            qw{ for-each-ref --format=%(committer)
                --sort=-committerdate --count=1 refs/heads
          });
        if (my ($epoch, $tz) = $output =~ /\s(\d+)\s+([+-]\d+)$/) {
            my $dt = DateTime->from_epoch(epoch => $epoch);
            $dt->set_time_zone($tz);
            $last_change = $dt;
        }
        return $last_change;
    }


=head2 run_cmd

Call out to the C<git> binary and return a string consisting of the output.

=cut

        method run_cmd (@args) {
            unshift @args, ( '--git-dir' => $self->path );
            print STDERR 'RUNNING: ', $self->_git, qq[ @args], $/;

            open my $fh, '-|', $self->_git, @args
                or die "failed to run git command";
            binmode $fh, ':encoding(UTF-8)';

            my $output = do { local $/ = undef; <$fh> };
            close $fh;

            return $output;
        }

    has _git      => ( isa => NonEmptySimpleStr, is => 'ro', lazy_build => 1 );
    use File::Which;
    method _build__git {
        my $git = File::Which::which('git');

        if (!$git) {
            die <<EOR;
Could not find a git executable.
Please specify the which git executable to use in gitweb.yml
EOR
        }

        return $git;
    }
    has _gpp      => ( isa => 'Git::PurePerl',   is => 'rw', lazy_build => 1 );
    use Git::PurePerl;
    method _build__gpp {
        my $gpp = Git::PurePerl->new(gitdir => $self->path);
        return $gpp;
    }

    method project_dir (Path::Class::Dir $project) {
        my $dir = $project->stringify;
        $dir .= '/.git'
            if -f dir($dir)->file('.git/HEAD');
        return $dir;
    }

    
    # Compatibility

=head2 project_info

Returns a hash containing properties of this project. The keys will
be:

	name
	description (empty if .git/description is empty/unnamed)
	owner
	last_change

=cut

    method project_info {
        return {
            name => $self->name,
            description => $self->description,
            owner => $self->owner,
            last_change => $self->last_change,
        };
    };
    
} # end class
