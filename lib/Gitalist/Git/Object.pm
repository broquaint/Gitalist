use MooseX::Declare;
use Moose::Autobox;

class Gitalist::Git::Object {
    use MooseX::Types::Moose qw/Str Int/;
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use File::Stat::ModeString qw/mode_to_string/;
    # project and sha1 are required initargs
    has project => ( isa => 'Gitalist::Git::Project',
                     required => 1,
                     is => 'ro',
                     weak_ref => 1,
                     handles => [ 'run_cmd' ],
                 );
    has sha1 => ( isa => NonEmptySimpleStr,
               required => 1,
               is => 'ro' );

    has $_ => ( isa => NonEmptySimpleStr,
                  required => 1,
                  is => 'ro',
                  lazy_build => 1 )
        for qw/type modestr size/;

    # objects can't determine their mode or filename
    has file => ( isa => NonEmptySimpleStr,
                  required => 0,
                  is => 'ro' );
    has mode => ( isa => Int,
                required => 1,
                default => 0,
                is => 'ro' );

    method BUILD { $self->$_() for qw/type size modestr/ }

    foreach my $key (qw/ type size /) {
        method "_build_$key" {
            $self->_cat_file_with_flag(substr($key, 0, 1))->chomp;
        }
    }

    method _build_modestr {
        my $modestr = mode_to_string($self->mode);
        return $modestr;
    }

    method _cat_file_with_flag ($flag) {
        $self->run_cmd('cat-file', '-' . $flag, $self->{sha1})
    }

=head2 contents

Return the contents of a given file.

=cut

    # FIXME - Should be an attribute so it gets cached?
    method contents {
        if ( $self->type ne 'blob' ) {
            die "object $self->sha1 is not a file\n"
        }

        $self->_cat_file_with_flag('p');
    }

} # end class
