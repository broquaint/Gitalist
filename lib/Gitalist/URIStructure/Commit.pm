package Gitalist::URIStructure::Commit;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires 'base';

after 'base' => sub {
    my ($self, $c) = @_;
    confess("No repository in the stash")
        unless $c->stash->{Repository};
};

sub find : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $sha1part) = @_;
    # FIXME - Should not be here!
    $c->stash->{Commit} = $c->stash->{Repository}->get_object($sha1part)
        or $c->detach('/error404', "Couldn't find a object for '$sha1part' in XXXX!");
}

sub diff : Chained('find') CaptureArgs(0) {}

sub diff_fancy : Chained('diff') PathPart('') Args(0) {}

sub diff_plain : Chained('diff') PathPart('plain') Args(0) {}

sub tree : Chained('find') Args(0) {}

sub commit : Chained('find') PathPart('') {}

1;
