package Gitalist::Git::Types;

use MooseX::Types
    -declare => [qw/SHA1/];

use MooseX::Types::Common::String qw/NonEmptySimpleStr/;

subtype SHA1,
    as NonEmptySimpleStr,
    where { $_ =~ qr/^[0-9a-fA-F]{40}$/ },
    message { q/Str doesn't look like a SHA1./ };

coerce SHA1,
    from NonEmptySimpleStr,
    via { 1 };

1;
