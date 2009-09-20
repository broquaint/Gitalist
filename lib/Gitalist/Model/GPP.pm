package Gitalist::Model::GPP;

#use base 'Catalyst::Model::Adaptor';
use Moose;
use namespace::autoclean;

extends 'Catalyst::Model';

use Git::PurePerl;

has git => (
 #isa => 'Git::PurePerl'
  is       => 'ro',
  required => 1,
  lazy     => 1,
  default  => sub {
    my($self) = @_;
    return Git::PurePerl->new(
      directory => $self->project_path
    );
  },
);

has project => (
  is => 'rw',
  isa => 'Str',
);
has project_path => (
  is => 'rw',
);


sub ACCEPT_CONTEXT {
    my ( $self, $c ) = @_;
    $self->project( $c->req->param('p') );
    $self->project_path( $c->model('Git')->project_dir( $self->project ) );
    # XXX Or just return a new Git:PP object?
    return $self;
}

sub get_object {
  $_[0]->git->get_object($_[1]);
}

1;
