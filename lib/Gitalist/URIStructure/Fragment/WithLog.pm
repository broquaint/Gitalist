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
    $logargs{skip} = abs $page * $logargs{count}
        if $page;

    $c->stash(
       page      => $page,
       log_lines => [$repository->list_revs(%logargs)],
       refs      => $repository->references,
    );
};

1;
