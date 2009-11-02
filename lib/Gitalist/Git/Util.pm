use MooseX::Declare;

class Gitalist::Git::Util {
    use File::Which;
    use Git::PurePerl;
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    has gitdir => ( isa => "Path::Class::Dir", is => 'ro' );
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

    has _gpp      => ( isa => 'Git::PurePerl',   is => 'rw', lazy_build => 1 );
    method _build__gpp {
        my $gpp = Git::PurePerl->new(gitdir => $self->gitdir);
        return $gpp;
    }

    method run_cmd (@args) {
        unshift @args, ( '--git-dir' => $self->gitdir );
        print STDERR 'RUNNING: ', $self->_git, qq[ @args], $/;
        
        open my $fh, '-|', $self->_git, @args
            or die "failed to run git command";
        binmode $fh, ':encoding(UTF-8)';

        my $output = do { local $/ = undef; <$fh> };
        close $fh;

        return $output;
    }





#
} # end class
