use MooseX::Declare;

class Gitalist::ContentMangler::Transformer::HighlightCmd {
    use IPC::Run qw(run start);
    use File::Temp qw(tempfile);
    method transform(Str :$blob, Str :$filename) {
        return unless $filename =~ /\.(\w+)$/; # Hope the extension is obvious;
        my($tmpfh, $tmpfn) = tempfile;
        print {$tmpfh} $blob;
        close $tmpfh;
        run [highlight => qw/-O html -f --inline-css --style night -i/, $tmpfn, -S => $1], \my($in, $out, $err);
        return $out && { blob => $out, language => q[] };
    }
}
