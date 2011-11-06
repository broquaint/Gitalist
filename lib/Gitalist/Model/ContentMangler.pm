package Gitalist::Model::ContentMangler;
use Moose;
use MooseX::Types::Moose qw/HashRef/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use namespace::autoclean;

extends 'Catalyst::Model';

# XXX This could live as metadata somewhere or in the config or whatever..
has transform_params => (
    is => 'ro',
    isa => HashRef,
    default => sub { {
        blob => [qw/blob filename/],
        diff_fancy => [qw/diffs/],
    } },
);

sub process {
    my ($self, $c) = @_;

    my $config  = Gitalist->config->{'Model::ContentMangler'}; # XXX Yeah it's a bit ugly. Feh.
    my $action  = $c->action->name;
    my $mangler = $c->req->param('cm') || '';
    my $transformer = $config->{$action}{$mangler || 'default'};

    return unless $transformer;
    Class::MOP::load_class($transformer);
    
    my $result = $transformer->new()->transform(
        map { $_ => $c->stash->{$_} } @{ $self->transform_params->{$action} }
    ) || {};

    $c->stash->{mangled} = 1 if %$result;
    $c->stash(%$result);
}

__PACKAGE__->meta->make_immutable;
