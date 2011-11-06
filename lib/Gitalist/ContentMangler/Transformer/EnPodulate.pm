use MooseX::Declare;

# Currently a POC to demonstrate non SyntaxHighlight based
# CM::Transformer. The default output is ugly as sin.
class Gitalist::ContentMangler::Transformer::EnPodulate {
    use Pod::Simple::HTML;
    
    method transform(Str :$blob, Str :$filename) {
        my $p = Pod::Simple::HTML->new;
        $p->output_string(\my $html);
        $p->parse_string_document( $blob );
        $html =~ m{<body[^>]*>(.*?)</body>}s;
        return { blob => $1 };
    }
}
