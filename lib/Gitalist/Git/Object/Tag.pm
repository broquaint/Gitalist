package Gitalist::Git::Object::Tag;
use MooseX::Declare;

class Gitalist::Git::Object::Tag extends Gitalist::Git::Object {
    has '+type' => ( default => 'tag' );
    has '+_gpp_obj' => ( handles => [ 'object',
                                      'tag',
                                      'tagger',
                                      'tagged_time',
                                  ],
                         );

}

1;

__END__

__END__

=head1 NAME

Gitalist::Git::Object::Tag

=head1 DESCRIPTION

Gitalist::Git::Object::Tag.

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
