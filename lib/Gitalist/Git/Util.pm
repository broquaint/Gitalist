use MooseX::Declare;

class Gitalist::Git::Util {
    has git      => ( isa => NonEmptySimpleStr, is => 'ro', lazy_build => 1 );
    sub _build_git {
        my $git = File::Which::which('git');

        if (!$git) {
            die <<EOR;
Could not find a git executable.
Please specify the which git executable to use in gitweb.yml
EOR
        }

        return $git;
    }

    





#
} # end class
