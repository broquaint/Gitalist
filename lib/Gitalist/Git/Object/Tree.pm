package Gitalist::Git::Object::Tree;
use MooseX::Declare;

class Gitalist::Git::Object::Tree
    extends Gitalist::Git::Object
    with Gitalist::Git::Object::HasTree {
        has '+type' => ( default => 'tree' );
        has '+_gpp_obj' => ( handles => [ 'directory_entries',
                                      ],
                         );
    }

1;

__END__


=head1 NAME

Gitalist::Git::Object::Tree

=head1 DESCRIPTION

Gitalist::Git::Object::Tree.

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
