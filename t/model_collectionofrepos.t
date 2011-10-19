use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/../script/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use strict;
use warnings;

use Test::More;
use Test::Exception;
use FindBin;

use Moose ();
use Moose::Object;
use Moose::Autobox;
use Class::MOP::Class;
use Catalyst::Request;
use Catalyst::Response;
use Catalyst::Utils;
use Gitalist::Model::CollectionOfRepos;
use File::Temp qw/tempdir tempfile/;

my $mock_ctx_meta = Class::MOP::Class->create_anon_class( superclasses => ['Moose::Object'] );
$mock_ctx_meta->add_attribute($_, accessor => $_, required => 1) for qw/request response/;
$mock_ctx_meta->add_attribute('stash', accessor => 'stash', required => 1, default => sub { {} });
$mock_ctx_meta->add_around_method_modifier( stash => sub { # Nicked straight from Catalyst.pm
    my $orig = shift;
    my $c = shift;
    my $stash = $orig->($c);
    if (@_) {
        my $new_stash = @_ > 1 ? {@_} : $_[0];
        croak('stash takes a hash or hashref') unless ref $new_stash;
        foreach my $key ( keys %$new_stash ) {
          $stash->{$key} = $new_stash->{$key};
        }
    }
    return $stash;
});
our $ctx_gen = sub {
    my ($cb, $stash) = @_;
    $stash ||= {};
    my $ctx = $mock_ctx_meta->new_object(
        response => Catalyst::Response->new,
        request => Catalyst::Request->new,
        stash => { %$stash }, # Shallow copy to try and help the user out. Should we clone?
    );
    $ctx->response->_context($ctx);
    $ctx->request->_context($ctx);
    $cb->($ctx) if $cb;
    return $ctx;
};

local %ENV = %ENV;
delete $ENV{GITALIST_REPO_DIR};

throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), {}) }
    qr/Cannot find repository dir/, 'Blows up nicely with no repos dir';

throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repo_dir => '/does/not/exist' }) }
    qr|Cannot find repository dir: "/does/not/exist"|, 'Blows up nicely with repos dir does not exist';

{
    my $td = tempdir( CLEANUP => 1 );
    test_with_config({ repo_dir => $td }, 'repo_dir is tempdir');
    # NOTE - This is cheating, there isn't a real git repository here, so things will explode (hopefully)
    #        if we go much further..
    test_with_config({ repos => $td }, 'repos is tempdir (scalar)');
    test_with_config({ repos => [$td] }, 'repos is tempdir (array)');
}

# Note - we treat an empty list of repos as if it doesn't exist at all.
throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => [] } ) }
    qr/Cannot find repository dir/, 'Blows up nicely with no repos list';

throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => [ '/does/not/exist' ] } ) }
    qr/Cannot find repository directories/, 'Blows up nicely with repos list - 1 unknown item (array)';
throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => '/does/not/exist' } ) }
    qr/Cannot find repository directories/, 'Blows up nicely with repos list - 1 unknown item (scalar))';

throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => [ '/does/not/exist', '/also/does/not/exist' ] } ) }
    qr/Cannot find repository directories/, 'Blows up nicely with repos list - 2 unknown items';

throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => [ tempdir( CLEANUP => 1), '/also/does/not/exist' ] } ) }
    qr|Cannot find repository directories.*/also/does/not/exist|, 'Blows up nicely with repos list - 1 known, 1 unknown items';

{
    my $td = tempdir( CLEANUP => 1 );
    local %ENV = %ENV;
    $ENV{GITALIST_REPO_DIR} = $td;
    lives_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), {}) } 'GITALIST_REPO_DIR env variable works';
}

{
    my $i = test_with_config({ repo_dir => "$FindBin::Bin/lib/repositories"});
    is scalar($i->repositories->flatten), 3, 'Found 6 repos';
    isa_ok $i, 'Gitalist::Git::CollectionOfRepositories::FromDirectory';
}

{
    my $i = test_with_config({ repo_dir => "$FindBin::Bin/lib/repositories", search_recursively => 1 });
    is scalar($i->repositories->flatten), 7, 'Found 6 repos recursively using config';
    isa_ok $i, 'Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive';
}
 {
    my($tempfh, $wl) = tempfile(UNLINK => 1);
    print {$tempfh} "repo1";
    close $tempfh;
    my $i = test_with_config({ repo_dir => "$FindBin::Bin/lib/repositories", whitelist => $wl });
    is scalar($i->repositories->flatten), 1, 'Found 1 repos using whitelist';
    isa_ok $i, 'Gitalist::Git::CollectionOfRepositories::FromDirectory::WhiteList';
}

{
    my $i = test_with_config({ repos => [
        "$FindBin::Bin/lib/repositories/bare.git",
        "$FindBin::Bin/lib/repositories/repo1",
        "$FindBin::Bin/lib/repositories/nodescription",
    ]});
    is scalar($i->repositories->flatten), 3, 'Found 3 repos';
    isa_ok $i, 'Gitalist::Git::CollectionOfRepositories::FromListOfDirectories';
}

sub test_with_config {
    my ($config, $msg) = @_;
    my $ctx = $ctx_gen->();
        
    my $m;
    lives_ok { $m = Gitalist::Model::CollectionOfRepos->COMPONENT($ctx, $config) } $msg;
    ok $m, 'Has model';
    my $i = $m->ACCEPT_CONTEXT($ctx);
    ok $i, 'Has model instance from ACCEPT_CONTEXT';
    isnt $i, $m, 'Model instance returned from ACCEPT_CONTEXT not same as model';
    is $i, $m->ACCEPT_CONTEXT($ctx), 'Same model instance for same context';
    isnt $i, $m->ACCEPT_CONTEXT($ctx_gen->()), 'Different model instance for different context';
    return $i;
}

done_testing;
