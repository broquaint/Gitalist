use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use strict;
use warnings;
use Test::More qw/no_plan/;
use Test::Exception;
use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Head' }


my $revline="a92fb1c9282f7319099ce7f783c8be7d5360f6e3\0refs/heads/model-cleanup\0Zachary Stevens <zts\@cryptocracy.com> 1277601094 +0100";
my $instance = Gitalist::Git::Head->new($revline);
isa_ok($instance, 'Gitalist::Git::Head');

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
