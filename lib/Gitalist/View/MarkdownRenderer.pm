package Gitalist::View::MarkdownRenderer;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Text::Markdown qw(markdown);

sub proces {
    my($self, $c) = @_;

    $c->res->body($self->render($c, $c->res->body, $c->stash));
}

sub render {
    my ($self, $c, $blob, $args) = @_;

    sprintf '<div class="pod">%s</div>', markdown($blob);
}
