package Gitalist::Model::ContentMangler;
use Moose;
use MooseX::Types::Moose qw/HashRef/;
use namespace::autoclean;

extends 'Catalyst::Model';

# FIXME - Never cleared!!
has _languages => (
    isa => HashRef,
    is => 'ro',
    default => sub { {} },
    traits => ['Hash'],
    handles => {
        _add_language => 'set',
        languages => 'keys',
        css => 'values',
    },
);

# FIXME This method is a gross hack.
#
# We need to work out what types of content mangles we have for various things based on hit type
# file name and mime type, and perform the appropriate bits..

# We need to support multiple languages, and we also want to be able to do HTMLizing (for e.g. Pod)

sub process {
    my ($self, $c) = @_;

    # XXX Hack hack hack
    my $language = $c->stash->{language} || '';
    $language = 'Perl' if $c->stash->{filename} =~ /\.p[lm]$/i;
    # FIXME - MOAR..

    $self->_add_language($language, $c->uri_for('/static/css/syntax/' . $language . '.css')) if $language;
    
    if ($c->stash->{blobs} || $c->stash->{blob}) {
        for($c->stash->{blobs} ? @{$c->stash->{blobs}} : $c->stash->{blob}) {
            $_ = $c->view('SyntaxHighlight')->render($c, $_, { language => $language });
        }
    }
}

__PACKAGE__->meta->make_immutable;
