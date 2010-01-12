package Gitalist::View::SyntaxHighlight;
use Moose;
use namespace::autoclean;

extends 'Catalyst::View';

use Syntax::Highlight::Engine::Kate ();
use Syntax::Highlight::Engine::Kate::Perl ();

use HTML::Entities qw(encode_entities);

# What should be done, but isn't currently:
#
# broquaint> Another Cat question - if I want to have arbitrary things highlighted is pushing things through a View at all costs terribly wrong?
# broquaint> e.g modifying this slightly to highlight anything (or arrays of anything) http://github.com/broquaint/Gitalist/blob/a7cc1ede5f9729465bb53da9c3a8b300a3aa8a0a/lib/Gitalist/View/SyntaxHighlight.pm
#       t0m> no, that's totally fine.. I'd tend to push the rendering logic into a model, so you end up doing something like: $c->model('SyntaxDriver')->highlight_all($stuff, $c->view('SyntaxHighlight'));
# broquaint> I'm thinking it's a bad idea because the Controller needs to munge data such that the View knows what to do
# broquaint> You just blew my mind ;)
#       t0m> ^^ That works _much_ better if you split up your view methods into process & render..
#       t0m> ala TT..
#       t0m> i.e. I'd have 'highlight this scalar' as the ->render method in the view..
#       t0m> And then the 'default' thing (i.e. process method) will do that and shove the output in the body..
#       t0m> but then you can write foreach my $thing (@things) { push(@highlighted_things, $c->view('SyntaxHighlight')->render($thing)); }
#       t0m> and then I'd move that ^^ loop down into a model which actually knows about / abstracts walking the data structures concerned..
#       t0m> But splitting render and process is the most important bit.. :) Otherwise you need to jump through hoops to render things that don't fit 'nicely' into the bits of stash / body that the view uses by 'default'
#       t0m> I wouldn't kill you for putting the structure walking code in the view given you're walking simple arrays / hashes.. It becomes more important if you have a more complex visitor..
#       t0m> (I use Visitor in the design patterns sense)
#       t0m> As the visitor is responsible for walking the structure, delegating to the ->render call in the view which is responsible for actually mangling the content..

sub process {
    my($self, $c) = @_;

    for($c->stash->{blobs} ? @{$c->stash->{blobs}} : $c->stash->{blob}) {
        $_ = $self->render($c, $_, { language => $c->stash->{language} });
    }

    $c->forward('View::Default');
}

sub render {
    my ($self, $c, $blob, $args) = @_;
    
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
