package Gitalist::Model::CollectionOfRepos;

use Moose;
use MooseX::Types::Moose qw/Maybe ArrayRef/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
use Moose::Util::TypeConstraints;
use Moose::Autobox;
use namespace::autoclean;

extends 'Catalyst::Model';

with 'Catalyst::Component::ApplicationAttribute';
with 'Catalyst::Component::InstancePerContext';

my $repo_dir_t = subtype NonEmptySimpleStr,
    where { -d $_ },
    message { 'Cannot find repository dir: "' . $_ . '", please set up gitalist.conf, or set GITALIST_REPO_DIR environment or pass the --repo_dir parameter when starting the application' };

my $arrayof_repos_dir_t = subtype ArrayRef[$repo_dir_t],
    where { 1 },
    message { 'Cannot find repository directories listed in config - these are invalid directories: ' . join(', ', $_->flatten) };

coerce $arrayof_repos_dir_t,
    from NonEmptySimpleStr,
    via { [ $_ ] };

has config_repo_dir => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    init_arg => 'repo_dir',
    predicate => 'has_config_repo_dir',
);

has repo_dir => (
    isa => $repo_dir_t,
    is => 'ro',
    lazy_build => 1
);

has repos => (
    isa => $arrayof_repos_dir_t,
    is => 'ro',
    default => sub { [] },
    traits => ['Array'],
    handles => {
        _repos_count => 'count',
    },
    coerce => 1,
);

has class => (
    isa => LoadableClass,
    is  => 'ro',
    is => 'lazy',
    builder => '_build_class',
);

sub _build_class {
    my($self) = @_;

    if($self->whitelist && -f $self->whitelist) {
        return 'Gitalist::Git::CollectionOfRepositories::FromDirectory::WhiteList';
    } elsif ($self->_repos_count && !$self->search_recursively) {
        return 'Gitalist::Git::CollectionOfRepositories::FromListOfDirectories';
    } elsif($self->search_recursively) {
        return 'Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive';
    }

    return 'Gitalist::Git::CollectionOfRepositories::FromDirectory';
}

has args => (
    isa     => 'HashRef',
    is      => 'ro',
    default => sub { {} },
);

has search_recursively => (
    is      => 'ro',
    isa     => 'Bool',
    default => 0,
);

has export_ok => (
    is  => 'ro',
    isa => 'Str',
);

has whitelist => (
    is  => 'ro',
    isa => 'Str',
);

sub _build_repo_dir {
    my $self = shift;
    my $repo_dir = $self->_application->run_options->{repo_dir};

    $repo_dir ?
        $repo_dir
      : $self->has_config_repo_dir
      ? $self->config_repo_dir
        : '';
}

after BUILD => sub {
    my $self = shift;
    # Explode loudly at app startup time if there is no list of
    # repositories or repos dir, rather than on first hit
    $self->_repos_count || $self->repo_dir;
};


sub build_per_context_instance {
    my ($self, $app) = @_;

    my %args = (
        export_ok => $self->export_ok || '',
        $self->_has_whitelist ? (whitelist => $self->whistlist) : (),
        $self->_has_repos ? (repos => $self->repos) : ()
        $self->_has_repo_dir ? (repo_dir => $self->repo_dir) : ()
        %{ $self->args }
    );

    my $class = $self->class;

    $app->log->debug("Using class '$class'");

    return $class->new(%args);
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding UTF-8

=head1 NAME

Gitalist::Model::CollectionOfRepos - Model::CollectionOfRepos module for Gitalist

=head1 DESCRIPTION

This Model is a factory for an object implementing the L<Gitalist::Git::CollectionOfRepositories>
interface.

The simple options passed on the command line (like C<--repos_dir>), a class will by picked by default 
L<Gitalist::Git::CollectionOfRepositories::FromDirectory>.

This can be overridden from config by explicitly passing in a class name and args for that class
in config:

    <Model::CollectionOfRepos>
        class MyClassName
        <args>
            ...
        </args>
    </Model::CollectionOfRepos>

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
