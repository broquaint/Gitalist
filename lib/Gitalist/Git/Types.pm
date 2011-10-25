package Gitalist::Git::Types;

use MooseX::Types
     -declare => [qw/
         SHA1
         Dir
     /];

use MooseX::Types::Path::Class;
use MooseX::Types::ISO8601 qw/ISO8601DateTimeStr/;
use MooseX::Types::DateTime qw/ DateTime /;
use MooseX::Storage::Engine ();
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;

subtype SHA1,
    as NonEmptySimpleStr,
    where { $_ =~ qr/^[0-9a-fA-F]{40}$/ },
    message { q/Str doesn't look like a SHA1./ };

coerce SHA1,
    from NonEmptySimpleStr,
    via { 1 };

MooseX::Storage::Engine->add_custom_type_handler(
    DateTime,
        expand   => sub {
            my $val = shift;
            Carp::confess("Not implemented");
        },
        collapse => sub {
            to_ISO8601DateTimeStr(shift);
        },
);

subtype Dir,
    as 'MooseX::Types::Path::Class::Dir',
    where { 1 };

MooseX::Storage::Engine->add_custom_type_handler(
    Dir,
        expand   => sub {
            my $val = shift;
            Carp::confess("Not implemented");
        },
        collapse => sub {
            shift() . '';
        },
);

1;
