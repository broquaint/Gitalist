use MooseX::Declare;

role Gitalist::ContentMangler::Transformer::SyntaxHighlightRole {
    use Syntax::Highlight::Engine::Kate ();
    use Syntax::Highlight::Engine::Kate::Perl ();

    use HTML::Entities qw(encode_entities);

    method highlight(Str $blob, Str $lang) {
        # Don't bother with anything over 128kb, it'll be tragically slow.
        return encode_entities $blob if length $blob > 131_072;
    
        my $ret;
        if ($lang) {
            # via http://github.com/jrockway/angerwhale/blob/master/lib/Angerwhale/Format/Pod.pm#L136
            $ret = eval {
                no warnings 'redefine';
                local *Syntax::Highlight::Engine::Kate::Template::logwarning
                     = sub { die @_ }; # i really don't care
                my $hl = Syntax::Highlight::Engine::Kate->new(
                    language      => $lang,
                    substitutions => {
                        "<"  => "&lt;",
                        ">"  => "&gt;",
                        "&"  => "&amp;",
                        q{'} => "&apos;",
                        q{"} => "&quot;",
                    },
                    format_table => {
                        # convert Kate's internal representation into
                        # <span class="<internal name>"> value </span>
                        map {
                            $_ => [ qq{<span class="$_">}, '</span>' ]
                        }
                             qw/Alert BaseN BString Char Comment DataType
                                DecVal Error Float Function IString Keyword
                                Normal Operator Others RegionMarker Reserved
                                String Variable Warning/,
                    },
                );

                my $hltxt = $hl->highlightText($blob);
                $hltxt =~ s/([^[:ascii:]])/encode_entities($1)/eg;
                $hltxt;
            };
            warn $@ if $@;
        }

        return $ret || encode_entities($blob);
    }
}
