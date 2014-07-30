use MooseX::Declare;
use Syntax::Highlight::Engine::Kate ();

our @interpreters = (
    'awk',
    'bash',
    'ksh',
    'make',
    'node',
    'perl',
    'prolog',
    'python',
    'ruby',
    'sh',
    'tcl',
);

our %interpretersx = (
    'awk'  => 'AWK',
    'ksh'  => 'Bash',
    'make' => 'Makefile',
    'node' => 'Javascript',
    'sh'   => 'Bash',
);

class Gitalist::ContentMangler::Resolver::Default with Gitalist::ContentMangler::Resolver {
    method resolve ($data) {
        if($data->{action} eq 'diff_fancy') {
            return 'Gitalist::ContentMangler::Transformer::SyntaxHighlight' => {language => 'Diff', css => 'Diff'};
        }
        my $kate = Syntax::Highlight::Engine::Kate->new();
        # Detect .t files as perl code
        $kate->extensions->{'*.t'} = ['Perl'];
        my $language = $kate->languagePropose($data->{filename}) || $kate->languagePropose(lc $data->{filename});
        if(!$language && exists($data->{blob})) {
            my $interp = substr(${$data->{blob}}, 0, 256);
            if($interp =~ /^#!(?:\S*\/)?([^\s\/]+)/) {
                my $interp = $1;

                for my $interpreter (@interpreters) {
                    if($interp =~ /$interpreter/) {
                        $language = $interpretersx{$interpreter} || ucfirst $interpreter;
                        last;
                    }
                }
            }
        }
        if($data->{action} eq 'html') {
            if(($language || '') eq 'Perl' || $data->{filename} =~ /\.pod$/) {
                return 'Gitalist::ContentMangler::Transformer::RenderPod' => {};
            }
            if($data->{filename} =~ /\.md$/) {
                return 'Gitalist::ContentMangler::Transformer::RenderMarkdown' => {};
            }
            return 'Gitalist::ContentMangler::Transformer::NoRenderer' => {};
        }
        return unless $language;
        return 'Gitalist::ContentMangler::Transformer::SyntaxHighlight' => {language => $language, css => 'Code'};
    }
}
