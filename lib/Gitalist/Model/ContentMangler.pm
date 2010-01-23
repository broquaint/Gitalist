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

    my @steps = $self->resolve({ filename => $c->stash->{filename} });
    my @css = map { $_->[1]->{css} } grep { exists $_->[1] && exists $_->[1]->{css} && defined $_->[1]->{css} && length $_->[1]->{css} } @steps;
    $c->stash(syntax_css => [ map { $c->uri_for('/static/css/syntax/' . $_ . '.css') } @css ]);
    
    if ($c->stash->{blobs} || $c->stash->{blob}) {
        foreach my $step (@steps) {
            for ($c->stash->{blobs} ? @{$c->stash->{blobs}} : $c->stash->{blob}) {
                $_ = $c->view($step->[0])->render($c, $_, $step->[1]);
            }
        }
    }
}

__PACKAGE__->meta->make_immutable;
