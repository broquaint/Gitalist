package Gitalist::View::PodRenderer;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Pod::Simple::HTML;

sub proces {
    my($self, $c) = @_;

    $c->res->body($self->render($c, $c->res->body, $c->stash));
}

sub render {
    my ($self, $c, $blob, $args) = @_;

    my $pod = Pod::Simple::HTML->new();
    my $ret;
    $pod->html_header_before_title('<div class="pod"><span style="display: none">');
    $pod->html_header_after_title("</span>");
    $pod->html_footer('</div>');
    $pod->output_string(\$ret);
    $pod->parse_string_document($blob);
    return $ret;
}
