use MooseX::Declare;

role Gitalist::Git::CollectionOfRepositories::Role::Context {
    requires qw/
        implementation_class
        ACCEPT_CONTEXT
    /;

    method implementation_class {
        $self->meta->name
    }
     
    method ACCEPT_CONTEXT($ctx) {
        return $self;
    }
}
