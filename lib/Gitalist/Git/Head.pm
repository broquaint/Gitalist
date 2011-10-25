package Gitalist::Git::Head;

use Moose;
use namespace::autoclean;

with 'Gitalist::Git::Serializable';

use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use MooseX::Types::Moose          qw/Maybe/;
use Gitalist::Git::Types          qw/SHA1/;
use MooseX::Types::DateTime       qw/DateTime/;

use aliased 'DateTime' => 'DT';

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
has last_change => ( isa      => Maybe[DateTime],
                     is       => 'ro',
                     required => 1,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        my $line = $_[0];
        # expects $line to match the output from
        # for-each-ref --format=%(objectname)%00%(refname)%00%(committer)
        my ($sha1, $name, $commitinfo) = split /\0/, $line, 3;
        $name =~ s!^refs/heads/!!;

        my ($committer, $epoch, $tz) =
            $commitinfo =~ /(.*)\s(\d+)\s+([+-]\d+)$/;
        my $dt = DT->from_epoch(
            epoch => $epoch,
            time_zone => $tz,
        );

        return $class->$orig(
            sha1 => $sha1,
            name => $name,
            committer => $committer,
            last_change => $dt,
        );
    } else {
        return $class->$orig(@_);
    }
};

1;
