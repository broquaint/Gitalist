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
    has commit => ( isa => 'Gitalist::Git::Object::Commit',
                    is => 'ro',
                    lazy_build => 1,
                  );

    method _build_commit {
        return Gitalist::Git::Object::Commit->new(
            repository => $self->repository,
            sha1       => $self->object,
            type       => 'commit',
        );
    }

    method tree {
      return [$self->repository->get_object($self->commit->tree_sha1)];
    }
}

1;

__END__

=head1 NAME

Gitalist::Git::Object::Tag - Git::Object::Tag module for Gitalist

=head1 SYNOPSIS

    my $tag = Repository->get_object($tag_sha1);

=head1 DESCRIPTION

Represents a tag object in a git repository.
Subclass of C<Gitalist::Git::Object>.


=head1 ATTRIBUTES

=head2 tag

=head2 tagger

=head2 tagged_time

=head2 object


=head1 METHODS


=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
