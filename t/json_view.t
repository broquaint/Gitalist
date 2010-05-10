#!/usr/bin/env perl

use FindBin qw/$Bin/;
BEGIN { do "$FindBin::Bin/../script/env" or die $@ }

use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use JSON::Any;


BEGIN {
    $ENV{GITALIST_CONFIG} = $Bin;
    $ENV{GITALIST_REPO_DIR} = '';
    use_ok 'Catalyst::Test', 'Gitalist';
}

my $j = JSON::Any->new;

my $res = request(GET 'http://localhost/repo1', 'Content-Type' => 'application/json');
is $res->code, 200;
my $data = $j->decode($res->content);
is ref($data), 'HASH';
delete $data->{owner}
  if $data && exists $data->{owner};
is_deeply $data, {
          'is_bare' => 1,
          '__CLASS__' => 'Gitalist::Git::Repository',
          'last_change' => '2009-11-12T19:00:34Z',
          'name' => 'repo1',
          'description' => 'some test repository'
        };

$res = request(GET 'http://localhost/repo1/3f7567c7bdf7e7ebf410926493b92d398333116e/commit', 'Content-Type' => 'application/json');
is $res->code, 200;
$data = $j->decode($res->content);
is ref($data), 'HASH';
delete $data->{repository}{owner}
  if $data && exists $data->{repository}{owner};
is_deeply $data, {
  'repository' => {
    'is_bare' => 1,
    '__CLASS__' => 'Gitalist::Git::Repository',
    'last_change' => '2009-11-12T19:00:34Z',
    'name' => 'repo1',
    'description' => 'some test repository'
  },
  '__CLASS__' => 'Gitalist::Git::Object::Commit',
  'sha1' => '3f7567c7bdf7e7ebf410926493b92d398333116e',
  'mode' => 0,
  'type' => 'commit',
  'modestr' => '----------',
  'size' => '218'
};

done_testing;


