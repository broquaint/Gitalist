use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}
use Test::NoTabs;
all_perl_files_ok(qw(t lib));

