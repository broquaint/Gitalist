package Gitalist::Controller::OPML;

use Moose;
use Moose::Autobox;
use DateTime;
use Sys::Hostname qw/hostname/;
use XML::OPML::SimpleGen;

use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }

sub opml : Chained('/base') Args(0) {
    my ($self, $c) = @_;

    my $opml = XML::OPML::SimpleGen->new();

    $c->stash(
        title => lc(hostname()) . ' - ' . blessed($c)->config->{name},
        Repositories => $c->model()->repositories,
        now => DateTime->now,
        template => 'opml.tt2',
        no_wrapper => 1,
    );

    $c->response->content_type('application/rss');
}

__PACKAGE__->meta->make_immutable;
