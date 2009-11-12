use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;
use Test::Exception;
use Data::Dumper;

use Path::Class;
use Gitalist::Git::Project;
my $project = Gitalist::Git::Project->new(
    dir("$Bin/lib/repositories/repo1"),
);

BEGIN { use_ok 'Gitalist::Git::Object' }

my $object = Gitalist::Git::Object->new(
    project => $project,
    sha1 => '729a7c3f6ba5453b42d16a43692205f67fb23bc1',
    type => 'tree',
    file => 'dir1',
    mode => 16384,
);
isa_ok($object, 'Gitalist::Git::Object');
is($object->sha1,'729a7c3f6ba5453b42d16a43692205f67fb23bc1', 'sha1 is correct');
is($object->type, 'tree', 'type is correct');
is($object->file, 'dir1', 'file is correct');
is($object->mode, 16384, 'mode is correct');
is($object->modestr, 'd---------', "modestr is correct" );
is($object->size, 33, "size is correct");

# Create object from sha1.
my $obj2 = Gitalist::Git::Object->new(
    project => $project,
    sha1 => '5716ca5987cbf97d6bb54920bea6adde242d87e6',
);
isa_ok($obj2, 'Gitalist::Git::Object');
is($obj2->sha1,'5716ca5987cbf97d6bb54920bea6adde242d87e6', 'sha1 is correct');
is($obj2->type, 'blob', 'type is correct');
is($obj2->mode, 0, 'mode is correct');
is($obj2->modestr, '?---------', "modestr is correct" );
is($obj2->content, "bar\n", 'obj2 contents is correct');
is($obj2->size, 4, "size is correct");
dies_ok {
    print $obj2->tree_sha1;
} 'tree_sha1 on a blob is an exception';
dies_ok {
    print $obj2->comment;
} 'comment is an empty string';
