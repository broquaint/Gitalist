use MooseX::Declare;

role Gitalist::Git::HasUtils {
    use Gitalist::Git::Util;

    method BUILD {}
    after BUILD {
        # Force value build
        $self->meta->get_attribute('_util')->get_read_method_ref->($self);
    }

    has _util => (
        isa => 'Gitalist::Git::Util',
        lazy => 1,
        is => 'bare',
        builder => '_build_util',
        handles => [qw/
            run_cmd
            run_cmd_fh
            run_cmd_list
            get_gpp_object
            gpp
        /],
    );
    method _build_util { confess(shift() . " cannot build _util") }
}

1;

__END__

=head1 NAME

Gitalist::Git::HasUtils - Role for classes with an instance of Gitalist::Git::Util

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
