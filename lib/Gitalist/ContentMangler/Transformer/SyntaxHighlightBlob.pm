use MooseX::Declare;

class Gitalist::ContentMangler::Transformer::SyntaxHighlightBlob
 with Gitalist::ContentMangler::Transformer::SyntaxHighlightRole {
     method transform(Str :$blob, Str :$filename) {
         return unless $filename =~ /\.p[lm]$/;
         return { blob => $self->highlight($blob, 'Perl'), language => 'Perl' };
     }
}
