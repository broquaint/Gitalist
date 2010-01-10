package Gitalist::Serializeable;
use Moose::Role;
use namespace::autoclean;
use MooseX::Storage;

with Storage( traits => [qw|OnlyWhenBuilt|] );

1;

=head1 NAME

Gitalist::Serializeable

=head1 SYNOPSIS

  class Gitalist::Git::Foo with Gitalist::Serializeable {
     ...
  }
  
=head1 DESCRIPTION

Role which applies a customised L<MooseX::Storage>.

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
