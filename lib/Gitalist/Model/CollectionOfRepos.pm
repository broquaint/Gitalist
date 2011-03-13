package Gitalist::Model::CollectionOfRepos;

use Moose;
use Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive;
use Gitalist::Git::CollectionOfRepositories::FromListOfDirectories;
use Gitalist::Git::CollectionOfRepositories::FromDirectory::WhiteList;
use MooseX::Types::Moose qw/Maybe ArrayRef/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use Moose::Util::TypeConstraints;
use Moose::Autobox;
use namespace::autoclean;

extends 'Catalyst::Model';

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
    $ENV{GITALIST_REPO_DIR} ?
        $ENV{GITALIST_REPO_DIR}
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

    my %args = (export_ok => $self->export_ok || '');
    my $class;
    if($self->whitelist && -f $self->whitelist) {
        $class = 'Gitalist::Git::CollectionOfRepositories::FromDirectory::WhiteList';
        $args{repo_dir}  = $self->repo_dir;
        $args{whitelist} = $self->whitelist;
    } elsif ($self->_repos_count && !$self->search_recursively) {
        $class = 'Gitalist::Git::CollectionOfRepositories::FromListOfDirectories';
        $args{repos} = $self->repos;
    } elsif($self->search_recursively) {
        $class = 'Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive';
        $args{repo_dir} = $self->repo_dir;
    } else {
        $class = 'Gitalist::Git::CollectionOfRepositories::FromDirectory';
        $args{repo_dir} = $self->repo_dir;
    }

    return $class->new(%args);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
