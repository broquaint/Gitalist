use MooseX::Declare;
use Moose::Autobox;

class Gitalist::Git::Object {
    use MooseX::Types::Moose qw/Str Int Bool Maybe ArrayRef/;
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use File::Stat::ModeString qw/mode_to_string/;

    # project and sha1 are required initargs
    has project => ( isa => 'Gitalist::Git::Project',
                     required => 1,
                     is => 'ro',
                     weak_ref => 1,
                     handles => {
                         _run_cmd => 'run_cmd',
                         _run_cmd_list => 'run_cmd_list',
                         _get_gpp_object => 'get_gpp_object',
                     },
                 );
    has sha1 => ( isa => NonEmptySimpleStr,
                  required => 1,
                  is => 'ro' );

    has $_ => ( isa => NonEmptySimpleStr,
                required => 1,
                is => 'ro',
                lazy_build => 1 )
        for qw/type modestr size/;

    has _gpp_obj => ( isa => 'Git::PurePerl::Object',
                      required => 1,
                      is => 'ro',
                      lazy_build => 1,
                      handles => [ 'content',
                               ],
                  );

    # objects can't determine their mode or filename
    has file => ( isa => NonEmptySimpleStr,
                  required => 0,
                  is => 'ro' );
    has mode => ( isa => Int,
                  required => 1,
                  default => 0,
                  is => 'ro' );

    method BUILD { $self->$_() for qw/_gpp_obj type size modestr/ }

## Private methods

## Builders
method _build__gpp_obj {
        return $self->_get_gpp_object($self->sha1)
    }

    foreach my $key (qw/ type size /) {
        method "_build_$key" {
            my $v = $self->_cat_file_with_flag(substr($key, 0, 1));
            chomp($v);
            return $v;
        }
    }

    method _build_modestr {
        my $modestr = mode_to_string($self->mode);
        return $modestr;
    }

    method _cat_file_with_flag ($flag) {
        $self->_run_cmd('cat-file', '-' . $flag, $self->{sha1})
    }

} # end class
