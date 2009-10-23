package Gitalist::View::SyntaxHighlight;
use Moose;
use Gitalist; # ->path_to
use namespace::autoclean;

extends 'Catalyst::View';

use Syntax::Highlight::Engine::Kate ();
use Syntax::Highlight::Engine::Kate::Perl ();

sub process {
    my($self, $c) = @_;
    # via
    # http://github.com/jrockway/angerwhale/blob/master/lib/Angerwhale/Format/Pod.pm#L136
    eval {
        no warnings 'redefine';
        local *Syntax::Highlight::Engine::Kate::Template::logwarning
          = sub { die @_ }; # i really don't care
        my $hl = Syntax::Highlight::Engine::Kate->new(
            language      => 'Perl',
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

        $c->stash->{blob} = $hl->highlightText($c->stash->{blob});
    };

    warn $@ if $@;

    $c->forward('View::Default');
}

__PACKAGE__->meta->make_immutable;
