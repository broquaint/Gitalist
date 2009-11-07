use MooseX::Declare;

class Gitalist::Git::Object {
    use MooseX::Types::Moose qw/Str Int/;
    use File::Stat::ModeString qw/mode_to_string/;
    # project and sha1 are required initargs
    has project => ( isa => 'Gitalist::Git::Project',
                     required => 1,
                     is => 'ro',
                     handles => [ 'run_cmd' ],
                 );
    has sha1 ( isa => Str,
               required => 1,
               is => 'ro' );

    has $_ => ( isa => Str,
                  required => 1,
                  is => 'ro',
                  lazy_build => 1 )
        for qw/type modestr size/;

    # objects can't determine their mode or filename
    has file => ( isa => Str,
                  required => 0,
                  is => 'ro' );
    has mode => ( isa => Int,
                required => 1,
                default => 0,
                is => 'ro' );

    method BUILD {
        $self->$_() for qw/type modestr size/; # Ensure to build early.
    }

    method _build_type {
        my $output = $self->run_cmd(qw/cat-file -t/, $self->{sha1});
        chomp($output);
        return $output;
    }

    method _build_modestr {
        my $modestr = mode_to_string($self->{mode});
        return $modestr;
    }

    method _build_size {
        my $output = $self->run_cmd(qw/cat-file -s/, $self->{sha1});
        chomp($output);
        return $output;
    }

=head2 contents

Return the contents of a given file.

=cut

    method contents {
        if ( $self->type ne 'blob' ) {
            die "object $self->sha1 is not a file\n"
        }

        my $output = $self->run_cmd(qw/cat-file -p/, $self->sha1);
        return unless $output;

        return $output;
    }

} # end class
