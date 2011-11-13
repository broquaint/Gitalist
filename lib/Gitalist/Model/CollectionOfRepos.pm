package Gitalist::Model::CollectionOfRepos;

use Moose;
use MooseX::Types::Moose qw/Undef Maybe ArrayRef Str/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use MooseX::Types::LoadableClass qw/ LoadableClass /;
use Gitalist::Git::Types qw/ ArrayRefOfDirs Dir DirOrUndef /;
use Moose::Util::TypeConstraints;
use Moose::Autobox;
use Path::Class qw/ dir /;
use namespace::autoclean;

extends 'Catalyst::Model';

with 'Catalyst::Component::ApplicationAttribute';
with 'Catalyst::Component::InstancePerContext';

has class => (
    isa => LoadableClass,
    is  => 'ro',
    lazy => 1,
    coerce => 1,
    builder => '_build_class',
);

sub _build_class {
    my ($self) = @_;

    if($self->whitelist && -f $self->whitelist) {
        return 'Gitalist::Git::CollectionOfRepositories::FromDirectory::WhiteList';
    }
    elsif($self->search_recursively) {
        return 'Gitalist::Git::CollectionOfRepositories::FromDirectoryRecursive';
    }
    elsif ($self->repos) {
        return 'Gitalist::Git::CollectionOfRepositories::FromListOfDirectories';
    }
    elsif ($self->repos_dir) {
        return 'Gitalist::Git::CollectionOfRepositories::FromDirectory';
    }
    else {
        return "Don't know where to get repositores from. Try a --repos_dir option, or setting up config";
    }
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

## XX What is this for?
has export_ok => (
    is  => 'ro',
    isa => 'Str',
);

has whitelist => (
    is  => 'ro',
    isa => 'Str',
    predicate => '_has_whitelist',
);

# Simple directory of repositories (for list)
has repos_dir => (
    is => 'ro',
    isa => DirOrUndef,
    coerce => 1,
    builder => '_build_repos_dir',
    lazy => 1,
);

# Directory containing list of one or more repositories
has repos => (
    is => 'ro',
    isa => ArrayRefOfDirs,
    coerce => 1,
);

sub _build_repos_dir {
    my $self = shift;
    my $dir = $self->_application->run_options->{repo_dir} || $ENV{GITALIST_REPO_DIR } || undef;
}

sub BUILD {
    my $self = shift;
    $self->class();
    if ($self->repos_dir) { $self->repos_dir->resolve }
}

sub build_per_context_instance {
    my ($self, $app) = @_;

    my %args = (
        export_ok => $self->export_ok || '',
        $self->_has_whitelist ? (whitelist => $self->whitelist) : (),
        repos => $self->repos,
        repo_dir => $self->repos_dir,
        %{ $self->args }
    );

    return $self->class->new(%args);
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
