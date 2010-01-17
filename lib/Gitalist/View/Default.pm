package Gitalist::View::Default;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View::TT';
with 'Catalyst::View::Component::SubInclude';

use Template::Plugin::Cycle;

__PACKAGE__->config(
  TEMPLATE_EXTENSION => '.tt2',
  WRAPPER            => 'default.tt2',
  subinclude_plugin => 'SubRequest',
);

__PACKAGE__->meta->make_immutable(inline_constructor => 0);

__END__

=head1 NAME

Gitalist::View::Default - HTML View

=head1 DESCRIPTION

HTML View.

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
