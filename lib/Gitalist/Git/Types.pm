package Gitalist::Git::Types;

use MooseX::Types
     -declare => [qw/
         SHA1
         Dir
         ArrayRefOfDirs
         DirOrUndef
     /];

use MooseX::Types::Path::Class;
use MooseX::Types::ISO8601 qw/ISO8601DateTimeStr/;
use MooseX::Types::DateTime qw/ DateTime /;
use MooseX::Storage::Engine ();
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use MooseX::Types::Moose qw/ ArrayRef Undef Str /;
use Path::Class qw/ dir /;

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
            $_[0]->ymd('-') . 'T' . $_[0]->hms(':') . 'Z' 
        },
);

subtype Dir,
    as 'MooseX::Types::Path::Class::Dir',
    where { 1 };

subtype ArrayRefOfDirs, as ArrayRef[Dir], where { scalar(@$_) >= 1 }, message { "Cannot find repository dir" };
coerce ArrayRefOfDirs, from NonEmptySimpleStr, via { [ dir($_)->resolve ] };
coerce ArrayRefOfDirs, from ArrayRef[NonEmptySimpleStr], via { [ map { dir($_)->resolve } @$_ ] };

subtype DirOrUndef, as Dir | Undef;
coerce DirOrUndef, from Str, via { if ($_) { dir($_) } else { undef }};

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
