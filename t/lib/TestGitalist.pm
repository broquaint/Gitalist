package TestGitalist;
use strict;
use warnings;
use Exporter qw/import/;
use Catalyst::Test qw/Gitalist/;
use Test::More;

our @EXPORT = qw/
    test_uri
    curry_test_uri
    MECH
/;

use constant ();
BEGIN {
    my $mech = eval {
        require Test::WWW::Mechanize::Catalyst;
        require WWW::Mechanize::TreeBuilder;
        my $mech = Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Gitalist');
        WWW::Mechanize::TreeBuilder->meta->apply($mech, {
           tree_class => 'HTML::TreeBuilder::XPath',
        } );
        return $mech;
    };
    constant->import('MECH', $mech );
}

# Rechecking the same link multiple times is slow and lame!
# Nicked this from WWW::Mechanize and memoized it...
my %seen_links;
sub Test::WWW::Mechanize::Catalyst::page_links_ok {
    my $self = shift;
    my $desc = shift;

    $desc = 'All links ok' unless defined $desc;

    my @links = $self->followable_links();
    my @urls = Test::WWW::Mechanize::_format_links(\@links);

    my @failures = $self->_check_links_status( [ grep { ! $seen_links{$_}++ } @urls ] );
    my $ok = (@failures==0);

    ok( $ok, $desc );
    diag( $_ ) for @failures;

    return $ok;
}


sub test_uri {
    my ($uri, $qs) = @_;
    my $request = "/$uri"; 
    $request .= "?$qs" if defined $qs;
    my $response = request($request);
    ok($response->is_success, "ok $request");
    if (MECH) {
        my $res = MECH()->get($request);
        ok $res->is_success, "ok mech $request (" . $res->code . ')';
        MECH()->page_links_ok("All links ok from $request")
            if $res->content_type =~ m|text/html|;
    }
    return $response;
}

sub curry_test_uri {
    my $prefix = shift;
    my $to_curry = shift || \&test_uri;
    sub {
        my $uri = shift;
        $to_curry->("$prefix/$uri", @_);
    };
}

1;
