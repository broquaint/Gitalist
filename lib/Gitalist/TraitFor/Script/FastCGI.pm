package Gitalist::TraitFor::Script::FastCGI;
use Moose::Role;
use namespace::autoclean;

sub BUILD {}

after BUILD => sub {
    require FCGI; # Make IPC::Run happy
    FCGI->VERSION(0.68);
};

1;

