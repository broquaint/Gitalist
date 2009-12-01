package Gitalist::Script::FastCGI;
use Moose;
use namespace::autoclean;

extends 'Catalyst::Script::FastCGI';

# Only exists so that this horrible hack can happen..
# This should be in FCGI.pm, see:
# http://github.com/broquaint/Gitalist/issues#issue/9
# http://rt.cpan.org/Public/Bug/Display.html?id=50972
# http://goatse.co.uk/~bobtfish/Gitalist/script/gitalist.fcgi/commitdiff?p=FCGI;h=6bfbe42bbc9a29f4befee56d6dd7077922cae50e
use FCGI;
sub FCGI::Stream::FILENO { -2 }

__PACKAGE__->meta->make_immutable;
