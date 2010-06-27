package Gitalist::Git::Head;
use MooseX::Declare;

class Gitalist::Git::Head {
    use Gitalist::Git::Types qw/SHA1/;
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::DateTime qw/DateTime/;

    has sha1        => ( isa      => SHA1,
                         is       => 'ro',
                         required => 1,
                     );
    has name        => ( isa      => NonEmptySimpleStr,
                         is       => 'ro',
                         required => 1,
                     );
    has committer   => ( isa      => NonEmptySimpleStr,
                         is       => 'ro',
                         required => 1,
                     );
    has last_change => ( isa      => DateTime,
                         is       => 'ro',
                         required => 1,
                         coerce   => 1,
                     );
}
