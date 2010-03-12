package Gitalist::URIStructure::Repository;
use MooseX::MethodAttributes::Role;
use Try::Tiny qw/try catch/;
use namespace::autoclean;

requires 'base';

with qw/
    Gitalist::URIStructure::WithLog
/;

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $repos_name) = @_;
    # XXX FIXME - This should be in the repository fragment controller, and the repository
    #             controller should just check has_repository
    try {
        my $repos = $c->model()->get_repository($repos_name);
        $c->stash(
            Repository => $repos,
            HEAD => $repos->head_hash,
        );
    }
    catch {
        $c->detach('/error_404');
    };
}

before 'log' => sub {
    my ($self, $c) = @_;
    $c->stash->{Commit} = $c->stash->{Repository}->get_object($c->stash->{Repository}->head_hash);
};

sub object : Chained('find') PathPart('') Args(1) {
    my ($self, $c, $sha1) = @_;

    my $repo = $c->stash->{Repository};
    my $obj  = $c->stash->{Commit} = $repo->get_object($sha1);
    my($act) = (ref($obj) || '') =~ /::(\w+)$/;

    $c->res->redirect($c->uri_for_action("/ref/\L$act", [$repo->name, $obj->sha1]));
    $c->res->status(301);

}

sub summary : Chained('find') PathPart('') Args(0) {}

sub heads : Chained('find') Args(0) {}

sub tags : Chained('find') Args(0) {}

1;
