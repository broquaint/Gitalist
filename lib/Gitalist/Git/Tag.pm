package Gitalist::Git::Tag;
use Moose;
use namespace::autoclean;

use Gitalist::Git::Types qw/SHA1/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use MooseX::Types::Moose qw/Maybe Str/;
use MooseX::Types::DateTime;
use DateTime;

has sha1        => ( isa      => SHA1,
                     is       => 'ro',
                     required => 1,
                 );
has name        => ( isa      => NonEmptySimpleStr,
                     is       => 'ro',
                     required => 1,
                 );

has type        => ( isa      => NonEmptySimpleStr,
                     is       => 'ro',
                     required => 1,
                 );

has ref_sha1    => ( isa      => Maybe[SHA1],
                     is       => 'ro',
                     required => 0,
                 );
has ref_type    => ( isa      => Maybe[NonEmptySimpleStr],
                     is       => 'ro',
                     required => 0,
                 );
has committer   => ( isa      => NonEmptySimpleStr,
                     is       => 'ro',
                     required => 1,
                 );
has last_change => ( isa      => 'DateTime',
                     is       => 'ro',
                     required => 1,
                     coerce   => 1,
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    if ( @_ == 1 && ! ref $_[0] ) {
        my $line = $_[0];
        # expects $line to match the output from
        # --format=%(objectname) %(objecttype) %(refname) %(*objectname) %(*objecttype) %(subject)%00%(creator)
        my ($sha1, $type, $name, $ref_sha1, $ref_type, $rest) = split / /, $line, 6;
        $name =~ s!^refs/tags/!!;

        unless ($ref_sha1) {
            ($ref_sha1, $ref_type) = (undef, undef);
        }
        my ($subject, $commitinfo) = split /\0/, $rest, 2;
        my ($committer, $epoch, $tz) =
            $commitinfo =~ /(.*)\s(\d+)\s+([+-]\d+)$/;
        my $dt = DateTime->from_epoch(
            epoch => $epoch,
            time_zone => $tz,
        );

        return $class->$orig(
            sha1 => $sha1,
            name => $name,
            type => $type,
            committer => $committer,
            last_change => $dt,
            ref_sha1 => $ref_sha1,
            ref_type => $ref_type,
        );
    } else {
        return $class->$orig(@_);
    }
};

sub is_valid_tag {
    local $_ = pop;
    # Ignore tags like - http://git.kernel.org/?p=git/git.git;a=tag;h=d6602ec
    return /^\S+ \S+ \S+ (?:\S+)? (?:\S+)?[^\0]+\0.*\s\d+\s+[+-]\d+$/;
}

1;
