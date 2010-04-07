package Gitalist::View::Default;
use Moose;
use Moose::Autobox;
use namespace::autoclean;

extends 'Catalyst::View::TT';
with 'Catalyst::View::Component::SubInclude';

use Template::Plugin::Cycle;

__PACKAGE__->config(
  TEMPLATE_EXTENSION => '.tt2',
  WRAPPER            => 'wrapper.tt2',
  subinclude_plugin => 'SubRequest',
);

use Template::Stash;

# define list method to flatten arrayrefs
$Template::Stash::LIST_OPS->{ to_path } = sub {
    my $path = join('%2F', shift->flatten, @_);
    $path =~ s{/}{%2F}g;
    return $path;
};

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
