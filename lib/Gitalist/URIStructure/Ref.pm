package Gitalist::URIStructure::Ref;
use MooseX::MethodAttributes::Role;
use Moose::Autobox;
use namespace::autoclean;

use Gitalist::Git::Types qw/SHA1/;

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
    $c->stash->{Commit} = $c->stash->{Repository}->get_object($sha1part)
        or $c->detach('/error404', "Couldn't find a object for '$sha1part' in XXXX!");
    $c->stash->{data} = $c->stash->{Commit};
}

sub diff : Chained('find') CaptureArgs(0) {}

sub _set_diff_args {
    my($self, $c, @rest) = @_;

    # FIXME - This ain't pretty
    $c->stash(parent   => shift @rest)
        if @rest == 2
        # Check that the single arg is unlikely to be a path.
        or @rest && to_SHA1($rest[0]) && $c->stash->{Repository}->get_object($rest[0]);
    $c->stash(filename => $rest[-1])
      if @rest;
}

sub diff_fancy : Chained('diff') PathPart('') Args() {
    my($self, $c, @rest) = @_;

    $self->_set_diff_args($c, @rest);
 }

sub diff_plain : Chained('diff') PathPart('plain') Args() {
    my($self, $c, $comparison, @rest) = @_;

    $self->_set_diff_args($c, @rest);

    $c->stash(no_wrapper => 1);
    $c->response->content_type('text/plain; charset=utf-8');
}

sub commit : Chained('find') PathPart('commit') Args(0) {}

sub file_commit_info : Chained('find') Does('FilenameArgs') Args() {}

sub tree : Chained('find') Does('FilenameArgs') Args() {}

sub find_blob : Action {
    my ($self, $c) = @_;
    my($repo, $object) = @{$c->{stash}}{qw(Repository Commit)};

    # FIXME - Eugh!
    my $blob;
    if ($object->isa('Gitalist::Git::Object::Commit')) {
        $blob = $object->sha_by_path($c->stash->{filename});
    } elsif ($object->isa('Gitalist::Git::Object::Blob')) {
        $blob = $object;
    } else {
        die "Unknown object type for '${\$object->sha1}'";
    }
    die "No file or sha1 provided."
        unless $blob;

    $c->stash(blob => $blob->content);
}

sub blob : Chained('find') Does('FilenameArgs') Args() {
    my ($self, $c) = @_;
    $c->forward('find_blob');
}

sub blame : Chained('find') Does('FilenameArgs') Args() {}

sub history : Chained('find') Does('FilenameArgs') Args() {}

1;
