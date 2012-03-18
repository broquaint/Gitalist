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
use lib "$Bin/lib"; # Used for testing of --model-class etc

use Moose ();
use Moose::Object;
use Moose::Autobox;
use Class::MOP::Class;
use Catalyst::Request;
use Catalyst::Response;
use Catalyst::Utils;
use Gitalist::Model::CollectionOfRepos;
use File::Temp qw/tempdir tempfile/;

my $run_options = {};
my $mock_ctx_meta = Class::MOP::Class->create_anon_class( superclasses => ['Moose::Object'] );
$mock_ctx_meta->add_method('run_options' => sub { $run_options });
$mock_ctx_meta->add_attribute($_, accessor => $_, required => 1) for qw/request response/;
$mock_ctx_meta->add_method('debug' => sub {});
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
my $mock_log = Moose::Meta::Class->create_anon_class( superclasses => ['Moose::Object'] );
$mock_log->add_method($_ => sub {}) for qw/ warn info debug /;
my $logger = $mock_log->name->new;
$mock_ctx_meta->add_method('log' => sub { $logger });

my $host = "git.shadowcat.co.uk";
$mock_ctx_meta->add_method('uri' => sub { URI->new("http://$host/") });
our $ctx_gen = sub {
    my ($cb, %args) = @_;
    my $ctx = $mock_ctx_meta->new_object(
        response    => Catalyst::Response->new,
        # Too lazy to mock up Catalyst::Log
        request     => Catalyst::Request->new(uri => URI->new("http://$host/"), _log => 1),
        stash       => {},
        %args
    );
    $cb->($ctx) if $cb;
    return $ctx;
};

local %ENV = %ENV;
delete $ENV{GITALIST_CONFIG};
delete $ENV{GITALIST_REPO_DIR};

throws_ok { my $i = Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), {}); $i->{_application} = $mock_ctx_meta->name; }
    qr/Don't know where to get repositores from/, 'Blows up nicely with no repos dir';

throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repo_dir => '/does/not/exist' }) }
    qr|No such file or directory|, 'Blows up nicely with repos dir does not exist';

{
    my $td = tempdir( CLEANUP => 1 );
    test_with_config({ repo_dir => $td }, msg => 'repo_dir is tempdir');
    # NOTE - This is cheating, there isn't a real git repository here, so things will explode (hopefully)
    #        if we go much further..
    test_with_config({ repos => $td }, msg => 'repos is tempdir (scalar)');
    test_with_config({ repos => [$td] }, msg => 'repos is tempdir (array)');
}

# Note - we treat an empty list of repos as if it doesn't exist at all.
throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => [] } ) }
    qr/Cannot find repository dir/, 'Blows up nicely with no repos list';

throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => [ '/does/not/exist' ] } ) }
    qr/No such file or directory/, 'Blows up nicely with repos list - 1 unknown item (array)';
throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => '/does/not/exist' } ) }
    qr/No such file or directory/, 'Blows up nicely with repos list - 1 unknown item (scalar))';

throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => [ '/does/not/exist', '/also/does/not/exist' ] } ) }
    qr/No such file or directory/, 'Blows up nicely with repos list - 2 unknown items';

throws_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), { repos => [ tempdir( CLEANUP => 1), '/also/does/not/exist' ] } ) }
    qr|No such file or directory|, 'Blows up nicely with repos list - 1 known, 1 unknown items';

{
    my $td = tempdir( CLEANUP => 1 );
    local %ENV = %ENV;
    $ENV{GITALIST_REPO_DIR} = $td;
    lives_ok { Gitalist::Model::CollectionOfRepos->COMPONENT($ctx_gen->(), {}) } 'GITALIST_REPO_DIR env variable works';
}

{
    my $i = test_with_config({ repo_dir => "$FindBin::Bin/lib/repositories"});
    is scalar($i->repositories->flatten), 3, 'Found 3 repos';
    isa_ok $i, 'Gitalist::Git::CollectionOfRepositories::FromDirectory';
}

{
    my $i = test_with_config({ repo_dir => "$FindBin::Bin/lib/repositories", search_recursively => 1 });
    is scalar($i->repositories->flatten), 7, 'Found 7 repos recursively using config';
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

{
    my $i = test_with_config({
        repo_dir => "$FindBin::Bin/lib/repositories",
        class    => 'TestModelSimple'
    });
    is scalar($i->repositories->flatten), 3, 'Found 3 repos';
    isa_ok $i, 'TestModelSimple';
}

{
    my $i = test_with_config({
        repo_dir => "$FindBin::Bin/lib/repositories",
        class    => 'TestModelFancy',
        args     => { fanciness => 1 },
    });
    is scalar($i->repositories->flatten), 1, 'Found 1 repo';
    isa_ok $i, 'TestModelFancy';
    ok $i->fanciness, "The TestModelFancy is fancy (so --model-args worked)";
}

sub test_vhost_instance {
    test_with_config({
        class    => 'Gitalist::Git::CollectionOfRepositories::Vhost',
        args     => {
            vhost_dispatch => {
                "git.shadowcat.co.uk" => "default",
                "git.moose.perl.org" => "moose",
                "git.catalyst.perl.org" => "catgit",
                "_default_" => "default",
            },
            collections => {
                moose => { class => 'Gitalist::Git::CollectionOfRepositories::FromDirectory', repo_dir => "$FindBin::Bin/lib/repositories_sets/moose" },
                catgit => { class => 'Gitalist::Git::CollectionOfRepositories::FromDirectory', repo_dir => "$FindBin::Bin/lib/repositories_sets/catgit" },
                default => { class => 'Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive', repo_dir => "$FindBin::Bin/lib/repositories_sets"},
            }
        },
    });
}

my $c_name = "$FindBin::Bin/lib/repositories_sets/catgit/Catalyst-Runtime";
my $m_name = "$FindBin::Bin/lib/repositories_sets/moose/Moose";
{
    my $i = test_vhost_instance();
    is scalar($i->repositories->flatten), 2, 'Found 2 repos on test vhost';
    my @r = $i->repositories->flatten;
    my @paths = sort map { $_->path . "" } $i->repositories->flatten;
    is_deeply \@paths, [sort $c_name, $m_name];
}

{
    $host = "git.moose.perl.org";
    my $i = test_vhost_instance();
    is scalar($i->repositories->flatten), 1, 'Found 1 repos on moose vhost';
    is $i->repositories->[0]->path.'', $m_name;
}

{
    $host = "git.catalyst.perl.org";
    my $i = test_vhost_instance();
    is scalar($i->repositories->flatten), 1, 'Found 1 repos on catalyst vhost';
    is $i->repositories->[0]->path.'', $c_name;
}

{
    $host = "git.shadowcat.co.uk";
    my $i = test_vhost_instance();
    is scalar($i->repositories->flatten), 2, 'Found 2 repos on git.shadowcat vhost';
    my @paths = sort map { $_->path . "" } $i->repositories->flatten;
    is_deeply \@paths, [sort $c_name, $m_name];
}

sub test_with_config {
    my ($config, %opts) = @_;
    my $msg = delete $opts{msg} || 'Built Model without exception';
    my $ctx = $ctx_gen->(undef, %opts);
    my $m;
    lives_ok { $m = Gitalist::Model::CollectionOfRepos->COMPONENT($ctx, $config) } $msg;
    ok $m, 'Has model';
    my $i = $m->ACCEPT_CONTEXT($ctx);
    ok $i, 'Has model instance from ACCEPT_CONTEXT';
    return $i;
}

done_testing;
