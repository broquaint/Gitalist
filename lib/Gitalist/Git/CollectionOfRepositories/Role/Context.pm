use MooseX::Declare;

role Gitalist::Git::CollectionOfRepositories::Role::Context {
    method implementation_class {
        $self->meta->name
    }
     
    method ACCEPT_CONTEXT($ctx) {
        return $self;
    }
}
