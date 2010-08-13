#!/usr/bin/env perl
use FindBin qw/$Bin/;
BEGIN {
    my $env = "$FindBin::Bin/script/env";
    if (-r $env) {
        do $env or die $@;
    }
}

use lib "$Bin/lib";
use TestGitalist;
plan 'skip_all' => "One or more of the following modules aren't present: Test::WWW::Mechanize::Catalyst WWW::Mechanize::TreeBuilder HTML::TreeBuilder::XPath" unless MECH();

MECH->get_ok('/');
{
    my $nodeset = MECH->findnodes('/html/body//tr[@class="reposrow"]');
    foreach my $row ($nodeset->get_nodelist) {
        my $uri = $row->findnodes('.//a')->[0]->attr('href');
        my ($repos_name) = $uri =~ m{^http://localhost/([\w\.]+)$};
        ok $repos_name, "Repos name $repos_name";
        like $row->findnodes('.//a')->[1]->as_text, qr{^[\w\s/;',\.]+$}, 'Have description'
            unless $repos_name eq 'nodescription';
        like $row->findnodes('.//td[@class="time-since"')->[0]->as_text, qr/^(never|\d\s+(years|months)\s+ago)$/,
            'Last change looks ok';
        my ($summary, $shortlog, $log, $tree) = $row->findnodes('.//td[@class="link"]/a')->get_nodelist;
        like $summary->as_text, qr/summary/i, 'summary text ok';
        is $summary->attr('href'), $uri, 'summary href correct';
        like $shortlog->as_text, qr/shortlog/i, 'shortlog text ok';
        is $shortlog->attr('href'), "$uri/shortlog", 'shortlog href ok';
        like $log->as_text, qr/log/, 'log text ok';
        is $log->attr('href'), "$uri/log", 'log href ok';
        like $tree->as_text, qr/tree/, 'tree text ok';
        TODO: {
            local $TODO = 'Bork';
            is $tree->attr('href'), "$uri/tree", 'tree href ok';
        }
    }
}

done_testing;
