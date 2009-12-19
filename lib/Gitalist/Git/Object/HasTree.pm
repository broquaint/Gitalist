package Gitalist::Git::Object::HasTree;
use MooseX::Declare;

role Gitalist::Git::Object::HasTree {
    has tree => ( isa => 'ArrayRef[Gitalist::Git::Object]',
                  required => 0,
                  is => 'ro',
                  lazy_build => 1 );


## Builders
    method _build_tree {
        my $output = $self->_run_cmd(qw/ls-tree -z/, $self->sha1);
        return unless defined $output;

        my @ret;
        for my $line (split /\0/, $output) {
            my ($mode, $type, $object, $file) = split /\s+/, $line, 4;
            my $class = 'Gitalist::Git::Object::' . ucfirst($type);
            push @ret, $class->new( mode => oct $mode,
                                    type => $type,
                                    sha1 => $object,
                                    file => $file,
                                    project => $self->project,
                                  );
        }
        return \@ret;
    }

}

1;


1;

__END__

=head1 NAME

Gitalist::Git::Object::HasTree

=head1 SYNOPSIS

    my $tree = Repository->get_object($tree_sha1);

=head1 DESCRIPTION

Role for objects which have a tree - C<Commit> and C<Tree> objects.


=head1 ATTRIBUTES

=head2 tree


=head1 METHODS


=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
