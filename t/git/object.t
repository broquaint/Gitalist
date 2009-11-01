use strict;
use warnings;
use FindBin qw/$Bin/;
use Test::More qw/no_plan/;

use Data::Dumper;

BEGIN { use_ok 'Gitalist::Git::Object' }

my $object = Gitalist::Git::Object->new(
    sha1 => '729a7c3f6ba5453b42d16a43692205f67fb23bc1',
    type => 'tree',
    file => 'dir1',
    mode => 16384,
);
isa_ok($object, 'Gitalist::Git::Object');

warn( Dumper($object) );
is($object->{sha1},'729a7c3f6ba5453b42d16a43692205f67fb23bc1', 'sha1 is correct');
is($object->{type}, 'tree', 'type is correct');
is($object->{file}, 'dir1', 'file is correct');
is($object->mode, 16384, 'mode is correct');
is($object->modestr, 'd---------', "modestr is correct" );

