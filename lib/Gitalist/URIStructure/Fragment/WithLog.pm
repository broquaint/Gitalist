package Gitalist::URIStructure::Fragment::WithLog;
use MooseX::MethodAttributes::Role;
use namespace::autoclean;

requires 'log';

after log => sub {
    my ($self, $c) = @_;
    my $repository  = $c->stash->{Repository};

    my %logargs = (
       sha1   => $c->stash->{Commit}->sha1, # $commit->sha1
       count  => 25, #Gitalist->config->{paging}{log} || 25,
    );

    my $page = $c->req->param('pg') || 0;
    $logargs{skip} = $c->req->param('pg') * $logargs{count}
        if $c->req->param('pg');
    $c->stash(
       log_lines => [$repository->list_revs(%logargs)],
       refs      => $repository->references,
    );
};

1;
