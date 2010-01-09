package Gitalist::Script::FastCGI;
use Moose;
use namespace::autoclean;

sub BUILD {
    require FCGI; # Make IPC::Run happy
    FCGI->VERSION(0.68);
}

extends 'Catalyst::Script::FastCGI';
with 'Gitalist::ScriptRole';

__PACKAGE__->meta->make_immutable;
