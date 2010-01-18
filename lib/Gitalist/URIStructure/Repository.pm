package Gitalist::URIStructure::Repository;
use MooseX::MethodAttributes::Role;
use Try::Tiny qw/try catch/;
use namespace::autoclean;

requires 'base';

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

sub summary : Chained('find') PathPart('') Args(0) {}

sub shortlog : Chained('find') Args(0) {}

sub heads : Chained('find') Args(0) {}

sub log : Chained('find') Args(0) {}

sub tags : Chained('find') Args(0) {}

1;
