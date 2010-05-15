use MooseX::Declare;

class Gitalist::ContentMangler::Resolver::Default with Gitalist::ContentMangler::Resolver {
    method resolve ($data) {
        # This should be pulled out of $self->config
        my $language;
        $language = 'Perl' if $data->{filename} =~ /\.p[lm]$/i;
        $language = 'Diff' if $data->{action} eq 'diff_fancy';
        return unless $language;
        return 'Gitalist::ContentMangler::Transformer::SyntaxHighlight' => {language => $language, css => $language};
    }
}
