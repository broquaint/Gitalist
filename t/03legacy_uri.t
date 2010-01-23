#!/usr/bin/env perl
use FindBin qw/$Bin/;
use lib "$Bin/lib";
use TestGitalist;

ok( request('/')->is_success, 'Request should succeed' );

# URI tests for repo1
local *test = curry_test_uri('repo1');

test('/', 'a=summary');
test('/', 'a=heads');
test('/', 'a=tags');

test('/', 'a=blob;f=dir1/file2;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=blob;f=dir1/file2;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=HEAD');
test('/', 'a=blob;f=dir1/file2;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=master');
test('/', 'a=blob;f=dir1/file2;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=refs/heads/master');
test('/', 'a=blob;f=dir1/file2;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=blob;f=file1;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99');
test('/', 'a=blob;f=file1;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=257cc5642cb1a054f08cc83f2d943e56fd3ebe99');
test('/', 'a=blob;f=file1;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blob;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=blob;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=blob;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=5716ca5987cbf97d6bb54920bea6adde242d87e6');
test('/', 'a=blob;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=HEAD');
test('/', 'a=blob;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=master');
test('/', 'a=blob;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=refs/heads/master');
test('/', 'a=blob;f=file1;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blob;f=file1;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');


test('/', 'a=blob_plain;f=dir1/file2;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=blob_plain;f=dir1/file2;hb=HEAD');
test('/', 'a=blob_plain;f=dir1/file2;hb=master');
test('/', 'a=blob_plain;f=dir1/file2;hb=refs/heads/master');
test('/', 'a=blob_plain;f=file1;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=blob_plain;f=file1;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blob_plain;f=file1;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=blob_plain;f=file1;hb=HEAD');
test('/', 'a=blob_plain;f=file1;hb=master');
test('/', 'a=blob_plain;f=file1;hb=refs/heads/master');

test('/', 'a=blobdiff;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blobdiff;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=3f7567c7bdf7e7ebf410926493b92d398333116e;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blobdiff;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=HEAD;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blobdiff;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=master;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blobdiff;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=refs/heads/master;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');

test('/', 'a=blobdiff_plain;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blobdiff_plain;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=3f7567c7bdf7e7ebf410926493b92d398333116e;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blobdiff_plain;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=HEAD;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blobdiff_plain;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hp=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=master;hpb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');

test('/', 'a=commit');
test('/', 'a=commit;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=commit;h=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=commit;h=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=commit;h=HEAD');
test('/', 'a=commit;h=master');
test('/', 'a=commit;h=refs/heads/master');
test('/', 'a=commit;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=commit;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=commit;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');

test('/', 'a=commitdiff');
test('/', 'a=commitdiff;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=commitdiff;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=commitdiff;h=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=commitdiff;h=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=commitdiff;h=3f7567c7bdf7e7ebf410926493b92d398333116e;hp=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=commitdiff;h=HEAD');
test('/', 'a=commitdiff;h=HEAD;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=commitdiff;h=master');
test('/', 'a=commitdiff;h=master;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=commitdiff;h=refs/heads/master');
test('/', 'a=commitdiff;h=refs/heads/master;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');

test('/', 'a=commitdiff_plain');
test('/', 'a=commitdiff_plain;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=commitdiff_plain;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=commitdiff_plain;h=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=commitdiff_plain;h=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=commitdiff_plain;h=3f7567c7bdf7e7ebf410926493b92d398333116e;hp=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=commitdiff_plain;h=HEAD');
test('/', 'a=commitdiff_plain;h=HEAD;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=commitdiff_plain;h=master');
test('/', 'a=commitdiff_plain;h=master;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=commitdiff_plain;h=refs/heads/master');
test('/', 'a=commitdiff_plain;h=refs/heads/master;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');


test('/', 'a=history;f=dir1/file2;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=history;f=dir1/file2;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=HEAD');
test('/', 'a=history;f=dir1/file2;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=master');
test('/', 'a=history;f=dir1/file2;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=refs/heads/master');
test('/', 'a=history;f=dir1;h=729a7c3f6ba5453b42d16a43692205f67fb23bc1;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=history;f=dir1;h=729a7c3f6ba5453b42d16a43692205f67fb23bc1;hb=HEAD');
test('/', 'a=history;f=dir1;h=729a7c3f6ba5453b42d16a43692205f67fb23bc1;hb=master');
test('/', 'a=history;f=dir1;h=729a7c3f6ba5453b42d16a43692205f67fb23bc1;hb=refs/heads/master');
test('/', 'a=history;f=dir1;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=history;f=dir1;hb=HEAD');
test('/', 'a=history;f=dir1;hb=master');
test('/', 'a=history;f=dir1;hb=refs/heads/master');
test('/', 'a=history;f=file1;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=history;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=history;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=history;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=HEAD');
test('/', 'a=history;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=master');
test('/', 'a=history;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=refs/heads/master');
test('/', 'a=history;f=file1;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=history;h=refs/heads/master');

test('/', 'a=log');
test('/', 'a=log;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=log;h=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=log;h=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=log;h=HEAD');
test('/', 'a=log;h=master');
test('/', 'a=log;h=refs/heads/master');

test('/', 'a=patch');
test('/', 'a=patch;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=patch;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=patch;h=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=patch;h=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=patch;h=3f7567c7bdf7e7ebf410926493b92d398333116e;hp=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=patch;h=HEAD');
test('/', 'a=patch;h=HEAD;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=patch;h=master');
test('/', 'a=patch;h=master;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=patch;h=refs/heads/master');
test('/', 'a=patch;h=refs/heads/master;hp=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=patch;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=patch;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=patch;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');

test('/', 'a=patches');
test('/', 'a=patches;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=patches;h=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=patches;h=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=patches;h=HEAD');
test('/', 'a=patches;h=master');
test('/', 'a=patches;h=refs/heads/master');

test('/', 'a=search_help');

test('/', 'a=shortlog');
test('/', 'a=shortlog;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=shortlog;h=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=shortlog;h=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=shortlog;h=HEAD');
test('/', 'a=shortlog;h=master');
test('/', 'a=shortlog;h=refs/heads/master');

test('/', 'a=snapshot;h=145dc3ef5d307be84cb9b325d70bd08aeed0eceb;sf=tgz');
test('/', 'a=snapshot;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818;sf=tgz');
test('/', 'a=snapshot;h=3bc0634310b9c62222bb0e724c11ffdfb297b4ac;sf=tgz');
test('/', 'a=snapshot;h=3f7567c7bdf7e7ebf410926493b92d398333116e;sf=tgz');
test('/', 'a=snapshot;h=729a7c3f6ba5453b42d16a43692205f67fb23bc1;sf=tgz');
test('/', 'a=snapshot;h=82b5fee28277349b6d46beff5fdf6a7152347ba0;sf=tgz');
test('/', 'a=snapshot;h=9062594aebb5df0de7fb92413f17a9eced196c22;sf=tgz');
test('/', 'a=snapshot;h=HEAD;sf=tgz');
test('/', 'a=snapshot;h=master;sf=tgz');
test('/', 'a=snapshot;h=refs/heads/master;sf=tgz');

test('/', 'a=tree');
test('/', 'a=tree;f=dir1;h=729a7c3f6ba5453b42d16a43692205f67fb23bc1;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=tree;f=dir1;h=729a7c3f6ba5453b42d16a43692205f67fb23bc1;hb=HEAD');
test('/', 'a=tree;f=dir1;h=729a7c3f6ba5453b42d16a43692205f67fb23bc1;hb=master');
test('/', 'a=tree;f=dir1;h=729a7c3f6ba5453b42d16a43692205f67fb23bc1;hb=refs/heads/master');
test('/', 'a=tree;f=dir1;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=tree;f=dir1;hb=HEAD');
test('/', 'a=tree;f=dir1;hb=master');
test('/', 'a=tree;f=dir1;hb=refs/heads/master');
test('/', 'a=tree;h=145dc3ef5d307be84cb9b325d70bd08aeed0eceb;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=tree;h=145dc3ef5d307be84cb9b325d70bd08aeed0eceb;hb=HEAD');
test('/', 'a=tree;h=145dc3ef5d307be84cb9b325d70bd08aeed0eceb;hb=master');
test('/', 'a=tree;h=145dc3ef5d307be84cb9b325d70bd08aeed0eceb;hb=refs/heads/master');
test('/', 'a=tree;h=36c6c6708b8360d7023e8a1649c45bcf9b3bd818;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=tree;h=3bc0634310b9c62222bb0e724c11ffdfb297b4ac;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=tree;h=3f7567c7bdf7e7ebf410926493b92d398333116e;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=tree;h=82b5fee28277349b6d46beff5fdf6a7152347ba0;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=tree;h=9062594aebb5df0de7fb92413f17a9eced196c22;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=tree;h=HEAD;hb=HEAD');
test('/', 'a=tree;h=master;hb=master');
test('/', 'a=tree;h=refs/heads/master;hb=master');
test('/', 'a=tree;h=refs/heads/master;hb=refs/heads/master');
test('/', 'a=tree;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=tree;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=tree;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=tree;hb=HEAD');
test('/', 'a=tree;hb=master');
test('/', 'a=tree;hb=refs/heads/master');


test('/', 'a=atom');
test('/', 'a=atom;f=dir1');
test('/', 'a=atom;f=dir1/file2');
test('/', 'a=atom;f=dir1/file2;opt=--no-merges');
test('/', 'a=atom;f=dir1;h=refs/heads/master');
test('/', 'a=atom;f=dir1;h=refs/heads/master;opt=--no-merges');
test('/', 'a=atom;f=dir1;opt=--no-merges');
test('/', 'a=atom;f=file1');
test('/', 'a=atom;f=file1;h=refs/heads/master');
test('/', 'a=atom;f=file1;h=refs/heads/master;opt=--no-merges');
test('/', 'a=atom;f=file1;opt=--no-merges');
test('/', 'a=atom;h=refs/heads/master');
test('/', 'a=atom;h=refs/heads/master;opt=--no-merges');
test('/', 'a=atom;opt=--no-merges');

test('/', 'a=rss');
test('/', 'a=rss;f=dir1');
test('/', 'a=rss;f=dir1/file2');
test('/', 'a=rss;f=dir1/file2;opt=--no-merges');
test('/', 'a=rss;f=dir1;h=refs/heads/master');
test('/', 'a=rss;f=dir1;h=refs/heads/master;opt=--no-merges');
test('/', 'a=rss;f=dir1;opt=--no-merges');
test('/', 'a=rss;f=file1');
test('/', 'a=rss;f=file1;h=refs/heads/master');
test('/', 'a=rss;f=file1;h=refs/heads/master;opt=--no-merges');
test('/', 'a=rss;f=file1;opt=--no-merges');
test('/', 'a=rss;h=refs/heads/master');
test('/', 'a=rss;h=refs/heads/master;opt=--no-merges');
test('/', 'a=rss;opt=--no-merges');

test('/', 'a=project_index');

test('/', 'a=opml');

test('/', 'a=blame;f=dir1/file2;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=blame;f=file1;h=257cc5642cb1a054f08cc83f2d943e56fd3ebe99;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blame;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=36c6c6708b8360d7023e8a1649c45bcf9b3bd818');
test('/', 'a=blame;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');
test('/', 'a=blame;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=HEAD');
test('/', 'a=blame;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=master');
test('/', 'a=blame;f=file1;h=5716ca5987cbf97d6bb54920bea6adde242d87e6;hb=refs/heads/master');
test('/', 'a=blame;f=file1;hb=3bc0634310b9c62222bb0e724c11ffdfb297b4ac');
test('/', 'a=blame;f=file1;hb=3f7567c7bdf7e7ebf410926493b92d398333116e');

done_testing;

