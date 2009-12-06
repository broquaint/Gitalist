package Gitalist::Script::CGI;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Script::CGI';
with 'Gitalist::ScriptRole';

__PACKAGE__->meta->make_immutable;

