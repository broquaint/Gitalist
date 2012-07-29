package Gitalist::View::SyntaxHighlight;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Syntax::Highlight::Engine::Kate ();

use HTML::Entities qw(encode_entities);

sub process {
    my($self, $c) = @_;

    $c->res->body($self->render($c, $c->res->body, $c->stash));
}

sub render {
    my ($self, $c, $blob, $args) = @_;

    # Don't bother with anything over 64kb, it'll be tragically slow.
    return encode_entities $blob if length $blob > 65536;

    my $lang = $args->{language};

    my $ret;
    if($lang) {
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

            # Line numbering breaks <span class="Other">#define foo\nbar</span>
            # So let's fix that by closing all spans at end-of-line and opening
            # new ones on the next, if needed.

            my @lines = split(/\n/, $hltxt);
            my $last_class = undef;
            map {
                unless($_ =~ s/^<\/span>//) {
                    if($last_class) {
                        $_ = "<span class=\"$last_class\">" . $_;
                    }
                }
                $last_class = undef;
                if($_ =~ /<span class="(.*?)">(?!.*<\/span>)/) {
                    $last_class = $1;
                }
                if($_ !~ /<\/span>$/) {
                    $_ .= "</span>";
                }
                $_;
            } @lines;

            $hltxt = join("\n", @lines);
            $hltxt =~ s/([^[:ascii:]])/encode_entities($1)/eg;
            $hltxt;
        };
        warn $@ if $@;
    }

    return $ret || encode_entities($blob);
}

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Gitalist::View::SyntaxHighlight - Responsible for syntax highlighting code

=head1 DESCRIPTION

Catalyst View for Syntax highlighting.

=head1 METHODS

=head2 process

=head2 highlight

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
