package Gitalist::Git::Object::Blob;
use MooseX::Declare;

class Gitalist::Git::Object::Blob extends Gitalist::Git::Object {
  has '+type' => ( default => 'blob' );
}

1;

__END__

=head1 NAME

Gitalist::Git::Object::Blob

=head1 SYNOPSIS

    my $blob = Project->get_object($blob_sha1);

=head1 DESCRIPTION

Represents a blob object in a git repository.
Subclass of C<Gitalist::Git::Object>.


=head1 ATTRIBUTES


=head1 METHODS

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
