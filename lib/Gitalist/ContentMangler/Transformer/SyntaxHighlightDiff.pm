use MooseX::Declare;

class Gitalist::ContentMangler::Transformer::SyntaxHighlightDiff
 with Gitalist::ContentMangler::Transformer::SyntaxHighlightRole {
     method transform(ArrayRef :$diffs) {
         return {
             language => 'Diff',
             blobs    => [map $self->highlight($_, 'Diff'), @$diffs],
         };
     }
}
