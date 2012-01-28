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
use Carp qw/croak/;

extends 'Catalyst::Model';

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
    elsif ($self->repo_dir) {
        return 'Gitalist::Git::CollectionOfRepositories::FromDirectory';
    }
    else {
        croak "Don't know where to get repositores from. Try a --repo_dir option, or setting up config";
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
has repo_dir => (
    is => 'ro',
    isa => DirOrUndef,
    coerce => 1,
    builder => '_build_repo_dir',
    lazy => 1,
);

# Directory containing list of one or more repositories
has repos => (
    is => 'ro',
    isa => ArrayRefOfDirs,
    coerce => 1,
);

sub _build_repo_dir {
    my $self = shift;
    return $ENV{GITALIST_REPO_DIR};
}

sub BUILD {
    my($self) = @_;

    $self->class();

    if ($self->repo_dir) { $self->repo_dir->resolve }
}

sub COMPONENT {
    my($class, $ctx, @args) = @_;

    my $self = $class->new($ctx, @args);

    my %args = (
        export_ok => $self->export_ok || '',
        repos      => $self->repos,
        repo_dir  => $self->repo_dir,
        $self->_has_whitelist ? (whitelist => $self->whitelist) : (),
        %{ $self->args }
    );

    my $model_class = $self->class;

    $ctx->log->debug("Building $model_class with " . join(", ", map { $_ . " => " . (defined($args{$_}) ? "'" . $args{$_}  . "'" : 'undef') } keys %args))
        if $ctx->debug;

    my $model = $model_class->new(\%args);

    $ctx->log->debug("Using class '$model_class' " . $model->debug_string) if $ctx->debug;

    return $model;
}

__PACKAGE__->meta->make_immutable;

__END__

=encoding UTF-8

=head1 NAME

Gitalist::Model::CollectionOfRepos - Model::CollectionOfRepos module for Gitalist

=head1 DESCRIPTION

This Model is a factory for an object implementing the L<Gitalist::Git::CollectionOfRepositories>
interface.

The simple options passed on the command line (like C<--repo_dir>), a class will by picked by default 
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
