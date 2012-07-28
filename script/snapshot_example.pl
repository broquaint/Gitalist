#!/usr/bin/perl
#
# This is an example of a custom snapshot generator for gitweb/gitalist. It is
# in active use by the perl 5 porters on perl5.git.perl.org.
#
# It doesn't do much, it only adds a .patch file with patch info as used by the
# perl build/test process.

use strict;
use warnings;

use Getopt::Long;
use POSIX qw(strftime);
use IPC::Cmd qw(run);
use Data::Dumper;
use File::Spec;
use File::Basename;
use version;

$ENV{PATH}="/usr/local/bin:/bin/:/usr/bin";

my $format = 'tar';
my $output;
my $git_dir;
my $prefix;

my $result = GetOptions(
    'format=s' => \$format,
    'output=s', => \$output,
    'git-dir=s', => \$git_dir,
    'prefix=s', => \$prefix,
);
my $sha1 = $ARGV[0];

# Get commit info:
# - branch name. If it's on multiple, prefer the name blead, then maint-*, then others
my $branches;
my $res = scalar run(
    command => [ "git", "--git-dir", $git_dir, "branch", "--contains", $sha1, '--all' ],
    buffer => \$branches,
);
chomp($branches);
my @branches = sort branchcmp (map { s/^..//; $_ } split(/\n/, $branches));
my $branch = $branches[0];
$branch =~ s![/ ]!-!g;

# - Abbreviated commit and timestamp
my ($sha1_abbrev,$timestamp);
$res = scalar run(
    command => [ "git", "--git-dir", $git_dir, "log", '--pretty=format:%h,%ct', '-1', $sha1 ],
    buffer => \$sha1_abbrev,
);
($sha1_abbrev, $timestamp) = split /,/, $sha1_abbrev;

# - And describe output
my $describe;
$res = scalar run(
    command => [ "git", "--git-dir", $git_dir, 'describe', $sha1 ],
    buffer => \$describe,
);
if(!$res) {
    $describe = "";
}
chomp($describe);

# Now create the base snapshot
run(
    command => ["git", "--git-dir", $git_dir, "archive",
        "--format", $format, "--prefix", $prefix,
        "--output", $output, $sha1],
);

# And add the .patch file
my $patch = File::Spec->catfile(dirname($output), "$sha1_abbrev.patch");
open(my $fh, ">", $patch);
print $fh join(" ", $branch, isotime($timestamp), $sha1, $describe);
run(
    command => ["tar", "-f", $output, '--transform', "s,.*$sha1_abbrev,$prefix,",
        "--owner=root", "--group=root", "--mode=664", "--append", $patch]
);

# Done :-)

sub branchcmp {
    return -1 if ($a eq 'blead');
    return 1 if ($b eq 'blead');
    return -1 if ($a =~ /^maint/ && $b !~ /^maint/);
    return 1 if ($a =~ /^maint/ && $b !~ /^maint/);
    return $a cmp $b if ($a !~ /^maint/ && $b !~ /^maint/);
    $a =~ s/maint-([0-9.]+).*/$1/;
    $b =~ s/maint-([0-9.]+).*/$1/;
    return version->parse($a) <=> version->parse($b);
}

sub isotime { strftime "%Y-%m-%d.%H:%M:%S",gmtime(shift||time) }
