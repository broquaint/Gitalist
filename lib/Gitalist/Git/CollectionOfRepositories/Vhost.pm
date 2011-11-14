use MooseX::Declare;

class Gitalist::Git::CollectionOfRepositories::Vhost
    with Gitalist::Git::CollectionOfRepositories {
    use MooseX::Types::Moose qw/ HashRef Str /;
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Path::Class qw/Dir/;
    use Moose::Util::TypeConstraints;

    sub BUILDARGS { # FIXME - This is fuck ugly!
        my ($class, @args) = @_;
        my $args = $class->next::method(@args);
        my %collections = %{ delete $args->{collections} };
        foreach my $name (keys %collections) {
            my %args = %{$collections{$name}};
            my $class = delete $args{class};
            Class::MOP::load_class($class);
            $collections{$name} = $class->new(%args);
        }
        my $ret = { %$args, collections => \%collections };
        return $ret;
    }

    has vhost_dispatch => (
        isa => HashRef,
        traits => ['Hash'],
        required => 1,
        handles => {
            _get_collection_name_for_vhost => 'get',
        },
    );

    has collections => (
        isa => HashRef,
        traits => ['Hash'],
        required => 1,
        handles => {
            _get_collection => 'get',
        }
    );

    has vhost => (
        is => 'ro',
        isa => Str,
        required => 1,
    );

    method debug_string { 'chosen collection ' . ref($self->chosen_collection) . " " . $self->chosen_collection->debug_string }

    role_type 'Gitalist::Git::CollectionOfRepositories';
    has chosen_collection => (
        does => 'Gitalist::Git::CollectionOfRepositories',
        handles => [qw/
            _get_repo_from_name
            _build_repositories
        /],
        default => sub {
            my $self = shift;
            $self->_get_collection($self->_get_collection_name_for_vhost($self->vhost) || $self->_get_collection_name_for_vhost('_default_'));
        },
        lazy => 1,
    );
}                               # end class

__END__

=head1 NAME

Gitalist::Git::CollectionOfRepositories::Vhost

=head1 SYNOPSIS

    my $repo = Gitalist::Git::CollectionOfRepositories::Vhost->new(
        vhost_dispatch => {
            "git.shadowcat.co.uk" => "foo",
            "git.moose.perl.org" => "bar",
            "_default_" => "foo",
        },
        collections => {
            foo => { class => Gitalist::Git::CollectionOfRepositories::XXX', %args },
            bar => { class => Gitalist::Git::CollectionOfRepositories::XXX', %args },
        }
    );
    my $repository_list = $repo->repositories;
    my $first_repository = $repository_list->[0];
    my $named_repository = $repo->get_repository('Gitalist');

=head1 DESCRIPTION

=head1 SEE ALSO

L<Gitalist::Git::CollectionOfRepositories>, L<Gitalist::Git::Repository>

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
