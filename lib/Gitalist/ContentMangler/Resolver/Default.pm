use MooseX::Declare;

class Gitalist::ContentMangler::Resolver::Default with Gitalist::ContentMangler::Resolver {
    method resolve ($data) {
        return unless $data->{filename};
        my $language = 'Perl' if $data->{filename} =~ /\.p[lm]$/i;
        return (['SyntaxHighlight', {language => $language, css => $language}]);
    }
}