use MooseX::Declare;

class Gitalist::Git::Object {
    use File::Stat::ModeString qw/mode_to_string/;

    has sha1 => ( isa => 'Str',
                  is => 'ro' );
    has type => ( isa => 'Str',
                  is => 'ro' );
    has file => ( isa => 'Str',
                  is => 'ro' );
    has mode => ( isa => 'Int',
                  is => 'ro' );
    has modestr => ( isa => 'Str',
                     is => 'ro',
                     lazy_build => 1,
                 );

    method _build_modestr {
        my $modestr = mode_to_string($self->{mode});
        return $modestr;
    }



} # end class
