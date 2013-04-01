use MooseX::Declare;
use Moose::Autobox;

class Gitalist::Git::Object with Gitalist::Git::Serializable is dirty {
    use MooseX::Storage::Meta::Attribute::Trait::DoNotSerialize;

    use MooseX::Types::Moose qw/Str Int Bool Maybe ArrayRef/;
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use Gitalist::Utils qw/mode_string/;
    use overload '""' => '_to_string', fallback => 1;

    # repository and sha1 are required initargs
    has repository => ( isa => 'Gitalist::Git::Repository',
                     required => 1,
                     is => 'ro',
                     weak_ref => 1,
                     handles => {
                         _run_cmd => 'run_cmd',
                         _run_cmd_fh => 'run_cmd_fh',
                         _run_cmd_list => 'run_cmd_list',
                         _get_gpp_object => 'get_gpp_object',
                     },
                 );
    has sha1 => ( isa => NonEmptySimpleStr,
                  required => 1,
                  is => 'ro' );

    has type => ( isa => NonEmptySimpleStr,
                  is => 'ro',
                  required => 1 );

    has $_ => ( isa => NonEmptySimpleStr,
                required => 1,
                is => 'ro',
                lazy_build => 1 )
        for qw/modestr size/;

    has _gpp_obj => ( isa        => 'Git::PurePerl::Object',
                      required   => 1,
                      is         => 'ro',
                      lazy_build => 1,
                      handles    => [ 'content' ],
                      traits     => ['DoNotSerialize']
                  );

    # objects can't determine their mode or filename
    has file => ( isa => NonEmptySimpleStr,
                  required => 0,
                  is => 'ro' );
    has mode => ( isa => Int,
                  required => 1,
                  default => 0,
                  is => 'ro' );

    method BUILD { $self->$_() for qw/_gpp_obj size modestr/ }

## Private methods
    method _to_string {
        return $self->sha1;
    };

## Builders
    method _build__gpp_obj {
        return $self->_get_gpp_object($self->sha1)
    }

    method "_build_size" {
        my $v = $self->_cat_file_with_flag('s');
        chomp($v);
        return $v;
    }

    method _cat_file_with_flag ($flag) {
        $self->_run_cmd('cat-file', '-' . $flag, $self->{sha1})
    }

    method _build_modestr {
        return mode_string($self->mode);
    }

} # end class

__END__

=head1 NAME

Gitalist::Git::Object - Model of a git object.

=head1 SYNOPSIS

    my $object = Repository->get_object($sha1);

=head1 DESCRIPTION

Abstract base class for git objects.


=head1 ATTRIBUTES


=head1 METHODS


=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
