package Gitalist::Controller::OPML;

use Moose;
use Moose::Autobox;

use Sys::Hostname qw/hostname/;
use XML::OPML::SimpleGen;

use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }

sub opml : Chained('base') Args(0) {
    my ($self, $c) = @_;

    my $opml = XML::OPML::SimpleGen->new();

    $opml->head(title => lc(hostname()) . ' - ' . blessed($c)->config->{name});

    for my $repos ( $c->model()->repositories->flatten ) {
        $opml->insert_outline(
            text   => $repos->name. ' - '. $repos->description,
            xmlUrl => $c->uri_for_action('/repository/rss', [$repos->name]),
        );
    }

    $c->response->body($opml->as_string);
    $c->response->content_type('application/rss');
}

__PACKAGE__->meta->make_immutable;
