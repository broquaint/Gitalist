use MooseX::Declare;

class Gitalist::ContentMangler::Transformer::SyntaxHighlight {
  method transform($c, $config) {
    $c->stash(
      syntax_css => $c->uri_for("/static/css/syntax/$config->{css}.css"),
      mangled    => 1,
    );
    for (grep $_, $c->stash->{blobs} ? @{$c->stash->{blobs}} : $c->stash->{blob}) {
      $_ = $c->view('SyntaxHighlight')->render($c, $_, $config);
    }
  }
}
