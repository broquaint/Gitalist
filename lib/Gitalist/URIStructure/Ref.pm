package Gitalist::URIStructure::Ref;
use MooseX::MethodAttributes::Role;
use Moose::Autobox;
use namespace::autoclean;

requires 'base';

with qw/
    Gitalist::URIStructure::WithLog
/;

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

sub diff_fancy : Chained('diff') PathPart('') Args() {
    my($self, $c, $comparison, @rest) = @_;
    # FIXME - This ain't pretty
    $c->stash(parent   => $comparison)
      if $comparison;
    $c->stash(filename => $rest[0])
      if @rest;
}

sub diff_plain : Chained('diff') PathPart('plain') Args() {
    my($self, $c, $comparison, @rest) = @_;
    # FIXME - This ain't pretty
    $c->stash(parent   => $comparison)
      if $comparison;
    $c->stash(filename => $rest[0])
      if @rest;
    $c->stash(no_wrapper => 1);
    $c->response->content_type('text/plain; charset=utf-8');
}

sub commit : Chained('find') PathPart('commit') Args(0) {}

sub tree : Chained('find') Does('FilenameArgs') Args() {}

sub find_blob : Action {
    my ($self, $c) = @_;
    my($repo, $object) = @{$c->{stash}}{qw(Repository Commit)};
    # FIXME - Eugh!
    my $h  = $object->isa('Gitalist::Git::Object::Commit')
           ? $repo->hash_by_path($object->sha1, $c->stash->{filename})
           : $object->isa('Gitalist::Git::Object::Blob')
             ? $object->sha1
             : die "Unknown object type for '${\$object->sha1}'";
    die "No file or sha1 provided."
        unless $h;
    $c->stash(blob => $repo->get_object($h)->content);
}

sub blob : Chained('find') Does('FilenameArgs') Args() {
    my ($self, $c) = @_;
    $c->forward('find_blob');
}

sub blame : Chained('find') Does('FilenameArgs') Args() {}

sub history : Chained('find') Does('FilenameArgs') Args() {}

1;
