use MooseX::Declare;

class Gitalist::ContentMangler::Transformer::RenderMarkdown {
  method transform($c, $config) {
    $c->stash(
      syntax_css => $c->uri_for("/static/css/syntax/Pod.css"),
      mangled    => 1,
    );
    for (grep $_, $c->stash->{blobs} ? @{$c->stash->{blobs}} : $c->stash->{blob}) {
      $_ = $c->view('MarkdownRenderer')->render($c, $_, $config);
    }
  }
}
