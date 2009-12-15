use MooseX::Declare;
use Gitalist::Git::Util;

role Gitalist::Git::HasUtils {

    method BUILD { }
    after BUILD {
        $self->meta->get_attribute('_util')->get_read_method_ref->($self); # Force value build.
    }

    has _util => ( isa => 'Gitalist::Git::Util',
                   lazy => 1,
                   is => 'bare',
                   builder => '_build_util',
                   handles => [ 'run_cmd',
                                'run_cmd_fh',
                                'run_cmd_list',
                                'get_gpp_object',
                                'gpp',
                            ],
               );

    sub _build_util { confess(shift() . " cannot build _util") }
}

1;

__END__

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
