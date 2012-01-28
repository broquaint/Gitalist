use MooseX::Declare;

role Gitalist::Git::CollectionOfRepositoriesWithRequestState {
    requires qw/
        implementation_class
        extract_request_state
    /;

    method ACCEPT_CONTEXT($c) {
        $self->implementation_class->new(%$self, $self->extract_request_state($c))->chosen_collection;
    }
}

