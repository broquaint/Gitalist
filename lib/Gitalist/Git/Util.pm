use MooseX::Declare;

class Gitalist::Git::Util {
    use File::Which;
    use Git::PurePerl;
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    has project => (
        isa => 'Gitalist::Git::Project',
        handles => { gitdir => 'project_dir' },
        is => 'bare', # No accessor
        weak_ref => 1, # Weak, you have to hold onto me.
        predicate => 'has_project',
    );
    has _git      => ( isa => NonEmptySimpleStr, is => 'ro', lazy_build => 1 );
    sub _build__git {
        my $git = File::Which::which('git');

        if (!$git) {
            die <<EOR;
Could not find a git executable.
Please specify the which git executable to use in gitweb.yml
EOR
        }

        return $git;
    }

    has _gpp      => (
        isa => 'Git::PurePerl', is => 'ro', lazy => 1,
        default => sub {
            my $self = shift;
            confess("Cannot get gpp without project")
                unless $self->has_project;
            Git::PurePerl->new(gitdir => $self->gitdir);
        },
    );

    method run_cmd (@args) {
        unshift @args, ( '--git-dir' => $self->gitdir )
            if $self->has_project;
#        print STDERR 'RUNNING: ', $self->_git, qq[ @args], $/;

        open my $fh, '-|', $self->_git, @args
            or die "failed to run git command";
        binmode $fh, ':encoding(UTF-8)';

        my $output = do { local $/ = undef; <$fh> };
        close $fh;

        return $output;
    }

    method get_gpp_object (NonEmptySimpleStr $sha1) {
        return $self->_gpp->get_object($sha1) || undef;
    }

} # end class
