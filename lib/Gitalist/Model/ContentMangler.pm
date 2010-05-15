package Gitalist::Model::ContentMangler;
use Moose;
use MooseX::Types::Moose qw/HashRef/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use Gitalist::ContentMangler::Resolver;
use namespace::autoclean;

extends 'Catalyst::Model';

has resolver_class => (
    isa => NonEmptySimpleStr,
    is => 'ro',
    required => 1,
    default => 'Gitalist::ContentMangler::Resolver::Default',
);

has resolver_config => (
    isa => HashRef,
    is => 'ro',
    default => sub { {} },
);

has _resolver => (
    does => 'Gitalist::ContentMangler::Resolver',
    handles => ['resolve'],
    is => 'bare', lazy => 1,
    default => sub {
        my $self = shift;
        my $class = $self->resolver_class;
        Class::MOP::load_class($class);
        return $class->new($self->resolver_config);
    },
);

# FIXME This method is a gross hack.
#
# We need to work out what types of content mangles we have for various things based on hit type
# file name and mime type, and perform the appropriate bits..

# We need to support multiple languages, and we also want to be able to do HTMLizing (for e.g. Pod)

sub process {
  my ($self, $c) = @_;

  # Find appropriate mangler based on filename,action,config
  # Mangler should provide a transform e.g what part of the stash to mangle
  # Then call the transform with the appropriate mangling

  my($transformer, $config) = $self->resolve({
    filename => $c->stash->{filename} || '',
    config   => Gitalist->config->{'Model::ContentMangler'},
    action   => $c->action->name,
  });

  return
       unless $transformer;

  Class::MOP::load_class($transformer);
  $transformer->new($config)->transform($c, $config);
}

__PACKAGE__->meta->make_immutable;
