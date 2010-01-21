package TestGitalist;
use strict;
use warnings;
use Exporter qw/import/;
use Catalyst::Test qw/Gitalist/;
use Test::More;

our @EXPORT = qw/
    test_uri
    curry_test_uri
/;

use constant ();
BEGIN {
    my $mech = eval {
        require Test::WWW::Mechanize::Catalyst;
        Test::WWW::Mechanize::Catalyst->new(catalyst_app => 'Gitalist')
    };
    constant->import('MECH', $mech );
}

sub test_uri {
    my ($uri, $qs) = @_;
    $qs ||= '';
    my $request = "/$uri"; 
    $request .= "?$qs" if defined $qs;
    my $response = request($request);
    ok($response->is_success, "ok $uri - $qs");
    if (MECH) {
        my $res = MECH()->get($request);
        ok $res->is_success, "ok mech $uri - $qs (" . $res->code . ')';
        MECH()->page_links_ok()
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
