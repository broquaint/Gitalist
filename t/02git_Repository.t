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
use Test::utf8;
use Encode qw/decode_utf8/;
use Data::Dumper;

BEGIN {
    # Mocking to allow testing regardless of the user's locale
    require I18N::Langinfo if $^O ne 'MSWin32';
    no warnings 'redefine';
    *I18N::Langinfo::langinfo = sub($) {
        return "UTF-8" if $_[0] == I18N::Langinfo::CODESET();
    };
    *CORE::GLOBAL::getpwuid = sub {
        wantarray
            ? ("test", "x", "1000", "1000", "", "", "T\x{c3}\x{a9}st", "/home/test", "/bin/bash")
            : "test";
    };
}

BEGIN { use_ok 'Gitalist::Git::Repository' }

dies_ok {
    my $proj = Gitalist::Git::Repository->new();
} 'New repository with no args';

use Path::Class;
my $gitdir = dir("$Bin/lib/repositories/repo1");

my $proj = Gitalist::Git::Repository->new($gitdir);
isa_ok($proj, 'Gitalist::Git::Repository');
is($proj->path, $gitdir, 'repository path is set');
isa_ok($proj->path, 'Path::Class::Dir', 'repository path');
is($proj->name, qw/repo1/, 'repository name is set');
is($proj->description, qq/some test repository/, 'repository description loaded');
isa_ok($proj->last_change, 'DateTime', 'last_change');

my %references = %{$proj->references};
ok(keys %references >= 2, '->references hash has elements');
is($references{'36c6c6708b8360d7023e8a1649c45bcf9b3bd818'}->[0], 'tags/0.01', 'reference looks ok');
my @heads = @{$proj->heads};
ok(scalar @heads > 1, '->heads list has more than one element');
my $head = $heads[1];
isa_ok($head, 'Gitalist::Git::Head');
is($proj->head_hash, 'd6ddf8b26be63066e01d96a0922c87cd8d6e2270', 'head_hash for HEAD is correct');
is($proj->head_hash('refs/heads/master'), 'd6ddf8b26be63066e01d96a0922c87cd8d6e2270', 'head_hash for refs/heads/master is correct');
is($proj->head_hash('rafs/head/mister'), undef, 'head_hash for rafs/head/mister is undef');

ok(scalar @{$proj->tags} == 1, '->tags list has one element');

# Return an ::Object from a sha1
my $obj1 = $proj->get_object('729a7c3f6ba5453b42d16a43692205f67fb23bc1');
isa_ok($obj1, 'Gitalist::Git::Object::Tree');

my $obj3 = $proj->get_object($proj->head_hash);
isa_ok($obj3, 'Gitalist::Git::Object::Commit');

my $obj2 = $obj3->sha_by_path('dir1/file2');
isa_ok($obj2, 'Gitalist::Git::Object::Blob');
is($obj2->type, 'blob', 'sha_by_path obj is a blob');
is($obj2->content, "foo\n", 'sha_by_path obj content is correct');


like($proj->head_hash('HEAD'), qr/^([0-9a-fA-F]{40})$/, 'head_hash');

{
    my @tree = @{$obj3->tree};
    is(scalar @tree, 1, "tree array contains one entry.");
    isa_ok($tree[0], 'Gitalist::Git::Object', 'tree element 0');
}

$proj->{owner} = decode_utf8("T\x{c3}\x{a9}st") if $^O eq 'MSWin32';

my $owner = $proj->owner;
is_flagged_utf8($owner, "Owner name is flagged as utf8");
is_sane_utf8($owner, "Owner name is not double-encoded");
is($owner, decode_utf8("T\x{c3}\x{a9}st"),  "Owner name is correct");

is_deeply $proj->pack,  {
    __CLASS__   => 'Gitalist::Git::Repository',
    description => 'some test repository',
    heads       => [
        {
            __CLASS__   => 'Gitalist::Git::Head',
            committer   => 'Dan Brook <broq@cpan.org>',
            last_change => '2011-06-05T23:00:44Z',
            name        => 'master',
            sha1        => 'd6ddf8b26be63066e01d96a0922c87cd8d6e2270',
        },
        {
            __CLASS__   => 'Gitalist::Git::Head',
            committer   => 'Zachary Stevens <zts@cryptocracy.com>',
            last_change => '2009-11-12T19:00:34Z',
            name        => 'branch1',
            sha1        => '0710a7c8ee11c73e8098d08f9384c2a839c65e4e'
        },
    ],
    is_bare     => 1,
    last_change => '2011-06-05T23:00:44Z',
    name        => 'repo1',
    owner       => "T\351st",
    references  => {
        "d6ddf8b26be63066e01d96a0922c87cd8d6e2270" => ['heads/master'],
        "36c6c6708b8360d7023e8a1649c45bcf9b3bd818" => ['tags/0.01'],
        "0710a7c8ee11c73e8098d08f9384c2a839c65e4e" => [ 'heads/branch1' ]
    },
    tags        => [ {
        __CLASS__
             => 'Gitalist::Git::Tag',
        committer
             => 'Florian Ragwitz <rafl@debian.org>',
        last_change
             => '2007-03-06T20:44:35Z',
        name    => 0.01,
        sha1    => '36c6c6708b8360d7023e8a1649c45bcf9b3bd818',
        type    => 'commit'
    } ]
}, 'Serialized correctly';
