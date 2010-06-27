use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;
use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Head' }


# Create an instance, passing last_change as a DateTime
use DateTime;
my $timespec = [1277578462, '+0100'];
my $dt = DateTime->from_epoch(
    epoch => @$timespec[0],
    time_zone => @$timespec[1],
);
my $head = Gitalist::Git::Head->new(
    sha1 => 'bca1153c22e393a952b6715bf2212901e4e77215',
    name => 'master',
    committer => 'Zachary Stevens <zts@cryptocracy.com>',
    last_change => $dt,
);
isa_ok($head, 'Gitalist::Git::Head');
