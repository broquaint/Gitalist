package Gitalist::Script::Server;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Script::Server';
with 'Gitalist::ScriptRole';

__PACKAGE__->meta->make_immutable;

