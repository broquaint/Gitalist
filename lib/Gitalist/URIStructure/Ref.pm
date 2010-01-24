package Gitalist::URIStructure::Ref;
use MooseX::MethodAttributes::Role;
use Moose::Autobox;
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
    $c->stash->{Commit} = $c->stash->{Repository}->get_object_or_head($sha1part)
        or $c->detach('/error404', "Couldn't find a object for '$sha1part' in XXXX!");
}

sub diff : Chained('find') CaptureArgs(0) {}

sub diff_fancy : Chained('diff') PathPart('') Args(0) {}

sub diff_plain : Chained('diff') PathPart('plain') Args(0) {}

sub commit : Chained('find') PathPart('commit') Args(0) {}

sub tree : Chained('find') Does('FilenameArgs') Args() {}

sub find_blob : Action {
    my ($self, $c) = @_;
    # FIXME - Eugh!
    my $h  = $c->stash->{Repository}->hash_by_path($c->stash->{Commit}->sha1, $c->stash->{filename})
           || die "No file or sha1 provided.";
    $c->stash(blob => $c->stash->{Repository}->get_object($h)->content);
}

sub blob : Chained('find') Does('FilenameArgs') Args() {
    my ($self, $c) = @_;
    $c->forward('find_blob');
}

sub blame : Chained('find') Does('FilenameArgs') Args() {}

sub history : Chained('find') Does('FilenameArgs') Args() {}

sub shortlog : Chained('find') Does('FilenameArgs') Args() {}

sub longlog : Chained('find') Does('FilenameArgs') PathPart('log') Args() {}

1;
