package Gitalist::Git::Object::Blob;
use MooseX::Declare;

class Gitalist::Git::Object::Blob extends Gitalist::Git::Object {
  has '+type' => ( default => 'blob' );
}

1;

__END__

=head1 NAME

Gitalist::Git::Object::Blob

=head1 DESCRIPTION

Gitalist::Git::Object::Blob.

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
