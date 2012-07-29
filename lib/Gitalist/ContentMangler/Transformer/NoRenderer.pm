use MooseX::Declare;

class Gitalist::ContentMangler::Transformer::NoRenderer {
  method transform($c, $config) {
    $c->stash(
      mangled    => 1,
    );
    for (grep $_, $c->stash->{blobs} ? @{$c->stash->{blobs}} : $c->stash->{blob}) {
      $_ = "No Renderer defined for this file format";
    }
  }
}
