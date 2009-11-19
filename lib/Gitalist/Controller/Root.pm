package Gitalist::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

use IO::Capture::Stdout;
use Sys::Hostname ();
use XML::Atom::Feed;
use XML::Atom::Entry;
use XML::RSS;

=head1 NAME

Gitalist::Controller::Root - Root Controller for Gitalist

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

=head2 run_gitweb

The C<gitweb> shim. It should now only be explicitly accessible by
modifying the URL.

=cut

sub run_gitweb {
  my ( $self, $c ) = @_;

  # XXX A slippery slope to be sure.
  if($c->req->param('a')) {
    my $capture = IO::Capture::Stdout->new();
    $capture->start();
    eval {
      my $action = gitweb::main($c);
      $action->();
    };
    $capture->stop();

    use Data::Dumper;
    die Dumper($@)
      if $@;

    my $output = join '', $capture->read;
    $c->stash->{gitweb_output} = $output;
    $c->stash->{template} = 'gitweb.tt2';
  }
}

sub _get_object {
  my($self, $c, $haveh) = @_;

  my $h = $haveh || $c->req->param('h') || '';
  my $f = $c->req->param('f');

  my $m = $c->stash->{Project};
  my $pd = $m->path;

  # Either use the provided h(ash) parameter, the f(ile) parameter or just use HEAD.
  my $hash = ($h =~ /[^a-f0-9]/ ? $m->head_hash($h) : $h)
          || ($f && $m->hash_by_path($f))
          || $m->head_hash
          # XXX This could definitely use more context.
          || Carp::croak("Couldn't find a hash for the commit object!");

  my $commit = $m->get_object($hash)
    or Carp::croak("Couldn't find a commit object for '$hash' in '$pd'!");

  return $commit;
}

=head2 index

Provides the project listing.

=cut

sub index :Path :Args(0) {
  my ( $self, $c ) = @_;

  $c->detach($c->req->param('a'))
    if $c->req->param('a');

  my @list = @{ $c->model()->projects };
  die 'No projects found in '. $c->model->repo_dir
    unless @list;

  my $search = $c->req->param('s') || '';
  if($search) {
    @list = grep {
         index($_->name, $search) > -1
      or ( $_->description !~ /^Unnamed repository/ and index($_->description, $search) > -1 )
    } @list
  }

  $c->stash(
    search_text => $search,
    projects    => \@list,
    action      => 'index',
  );
}

=head2 summary

A summary of what's happening in the repo.

=cut

sub summary : Local {
  my ( $self, $c ) = @_;
  my $project = $c->stash->{Project};
  $c->detach('error_404') unless $project;
  my $commit = $self->_get_object($c);
  my @heads  = @{$project->heads};
  my $maxitems = Gitalist->config->{paging}{summary} || 10;
  $c->stash(
    commit    => $commit,
    log_lines => [$project->list_revs(
        sha1 => $commit->sha1,
        count => $maxitems,
    )],
    refs      => $project->references,
    heads     => [ @heads[0 .. ($#heads < $maxitems ? $#heads : $maxitems)] ],
    action    => 'summary',
  );
}

=head2 heads

The current list of heads (aka branches) in the repo.

=cut

sub heads : Local {
  my ( $self, $c ) = @_;
  my $project = $c->stash->{Project};
  $c->stash(
    commit => $self->_get_object($c),
    heads  => $project->heads,
    action => 'heads',
  );
}

=head2 blob

The blob action i.e the contents of a file.

=cut

sub blob : Local {
  my ( $self, $c ) = @_;
  my $project = $c->stash->{Project};
  my $h  = $c->req->param('h')
       || $project->hash_by_path($c->req->param('hb'), $c->req->param('f'))
       || die "No file or sha1 provided.";
  my $hb = $c->req->param('hb')
       || $project->head_hash
       || die "Couldn't discern the corresponding head.";

  my $filename = $c->req->param('f') || '';

  $c->stash(
    blob     => $project->get_object($h)->content,
    head     => $project->get_object($hb),
    filename => $filename,
    # XXX Hack hack hack, see View::SyntaxHighlight
    language => ($filename =~ /\.p[lm]$/ ? 'Perl' : ''),
    action   => 'blob',
  );

  $c->forward('View::SyntaxHighlight')
    unless $c->stash->{no_wrapper};
}

sub blob_plain : Local {
  my($self, $c) = @_;

  $c->stash(no_wrapper => 1);
  $c->response->content_type('text/plain; charset=utf-8');

  $c->forward('blob');
}

sub blobdiff_plain : Local {
  my($self, $c) = @_;

  $c->stash(no_wrapper => 1);
  $c->response->content_type('text/plain; charset=utf-8');

  $c->forward('blobdiff');

}

=head2 blobdiff

Exposes a given diff of a blob.

=cut

sub blobdiff : Local {
  my ( $self, $c ) = @_;
  my $commit = $self->_get_object($c, $c->req->param('hb'));
  my $filename = $c->req->param('f')
              || croak("No file specified!");
  my($tree, $patch) = $c->stash->{Project}->diff(
    commit => $commit,
    patch  => 1,
    parent => $c->req->param('hpb') || undef,
    file   => $filename,
  );
  $c->stash(
    commit    => $commit,
    diff      => $patch,
    # XXX Hack hack hack, see View::SyntaxHighlight
    blobs     => [$patch->[0]->{diff}],
    language  => 'Diff',
    action    => 'blobdiff',
  );

  $c->forward('View::SyntaxHighlight')
    unless $c->stash->{no_wrapper};
}

=head2 commit

Exposes a given commit.

=cut

sub commit : Local {
  my ( $self, $c ) = @_;
  my $project = $c->stash->{Project};
  my $commit = $self->_get_object($c);
  $c->stash(
      commit      => $commit,
      diff_tree   => ($project->diff(commit => $commit))[0],
      refs      => $project->references,
      action      => 'commit',
  );
}

=head2 commitdiff

Exposes a given diff of a commit.

=cut

sub commitdiff : Local {
  my ( $self, $c ) = @_;
  my $commit = $self->_get_object($c);
  my($tree, $patch) = $c->stash->{Project}->diff(
      commit => $commit,
      parent => $c->req->param('hp') || undef,
      patch  => 1,
  );
  $c->stash(
    commit    => $commit,
    diff_tree => $tree,
    diff      => $patch,
    # XXX Hack hack hack, see View::SyntaxHighlight
    blobs     => [map $_->{diff}, @$patch],
    language  => 'Diff',
    action    => 'commitdiff',
  );

  $c->forward('View::SyntaxHighlight')
    unless $c->stash->{no_wrapper};
}

sub commitdiff_plain : Local {
  my($self, $c) = @_;

  $c->stash(no_wrapper => 1);
  $c->response->content_type('text/plain; charset=utf-8');

  $c->forward('commitdiff');
}

=head2 shortlog

Expose an abbreviated log of a given sha1.

=cut

sub shortlog : Local {
  my ( $self, $c ) = @_;
  my $project = $c->stash->{Project};
  my $commit  = $self->_get_object($c);
  my %logargs = (
      sha1   => $commit->sha1,
      count  => Gitalist->config->{paging}{log} || 25,
      ($c->req->param('f') ? (file => $c->req->param('f')) : ())
  );

  my $page = $c->req->param('pg') || 0;
  $logargs{skip} = $c->req->param('pg') * $logargs{count}
    if $c->req->param('pg');

  $c->stash(
      commit    => $commit,
      log_lines => [$project->list_revs(%logargs)],
      refs      => $project->references,
      action    => 'shortlog',
      page      => $page,
  );
}

=head2 log

Calls shortlog internally. Perhaps that should be reversed ...

=cut
sub log : Local {
    $_[0]->shortlog($_[1]);
    $_[1]->stash->{action} = 'log';
}

# For legacy support.
sub history : Local {
  $_[0]->shortlog(@_[1 .. $#_]);
}

=head2 tree

The tree of a given commit.

=cut

sub tree : Local {
  my ( $self, $c ) = @_;
  my $project = $c->stash->{Project};
  my $commit  = $self->_get_object($c, $c->req->param('hb'));
  my $tree    = $self->_get_object($c, $c->req->param('h') || $commit->tree_sha1);
  $c->stash(
      commit    => $commit,
      tree      => $tree,
      tree_list => [$project->list_tree($tree->sha1)],
      path      => $c->req->param('f') || '',
      action    => 'tree',
  );
}

=head2 reflog

Expose the local reflog. This may go away.

=cut

sub reflog : Local {
  my ( $self, $c ) = @_;
  my @log = $c->stash->{Project}->reflog(
      '--since=yesterday'
  );

  $c->stash(
      log    => \@log,
      action => 'reflog',
  );
}

sub search : Local {
  my($self, $c) = @_;
  $c->stash(current_action => 'GitRepos');
  my $project = $c->stash->{Project};
  my $commit  = $self->_get_object($c);
  # Lifted from /shortlog.
  my %logargs = (
    sha1   => $commit->sha1,
    count  => Gitalist->config->{paging}{log},
    ($c->req->param('f') ? (file => $c->req->param('f')) : ()),
    search => {
      type   => $c->req->param('type'),
      text   => $c->req->param('text'),
      regexp => $c->req->param('regexp') || 0,
    },
  );

  $c->stash(
      commit  => $commit,
      results => [$project->list_revs(%logargs)],
      action  => 'search',
	  # This could be added - page      => $page,
  );
}

sub search_help : Local {
    my ($self, $c) = @_;
    $c->stash(template => 'search_help.tt2');
}

sub atom : Local {
  my($self, $c) = @_;

  my $feed = XML::Atom::Feed->new;

  my $host = lc Sys::Hostname::hostname();
  $feed->title($host . ' - ' . Gitalist->config->{name});
  $feed->updated(~~DateTime->now);

  my $project = $c->stash->{Project};
  my %logargs = (
      sha1   => $project->head_hash,
      count  => Gitalist->config->{paging}{log} || 25,
      ($c->req->param('f') ? (file => $c->req->param('f')) : ())
  );

  my $mk_title = $c->stash->{short_cmt};
  for my $commit ($project->list_revs(%logargs)) {
    my $entry = XML::Atom::Entry->new;
    $entry->title( $mk_title->($commit->comment) );
    $entry->id($c->uri_for('commit', {h=>$commit->sha1}));
    # XXX Needs work ...
    $entry->content($commit->comment);
    $feed->add_entry($entry);
  }

  $c->response->body($feed->as_xml);
  $c->response->content_type('application/atom+xml')
  $c->response->status(200);
}

sub rss : Local {
  my ($self, $c) = @_;

  my $project = $c->stash->{Project};

  my $rss = XML::RSS->new(version => '2.0');
  $rss->channel(
    title          => lc(Sys::Hostname::hostname()) . ' - ' . Gitalist->config->{name},
    link           => $c->uri_for('summary', {p=>$project->name}),
    language       => 'en',
    description    => $project->description,
    pubDate        => DateTime->now,
    lastBuildDate  => DateTime->now,
  );

  my %logargs = (
      sha1   => $project->head_hash,
      count  => Gitalist->config->{paging}{log} || 25,
      ($c->req->param('f') ? (file => $c->req->param('f')) : ())
  );
  my $mk_title = $c->stash->{short_cmt};
  for my $commit ($project->list_revs(%logargs)) {
    # XXX Needs work ....
    $rss->add_item(
        title       => $mk_title->($commit->comment),
        permaLink   => $c->uri_for(commit => {h=>$commit->sha1}),
        description => $commit->comment,
    );
  }

  $c->response->body($rss->as_string);
  $c->response->content_type('application/rss+xml');
  $c->response->status(200);
}

sub patch : Local {
    my ($self, $c) = @_;
    $c->detach('patches', [1]);
}

sub patches : Local {
    my ($self, $c, $count) = @_;
    $count ||= Gitalist->config->{patches}{max};
    my $commit = $self->_get_object($c);
    my $parent = $c->req->param('hp') || undef;
    my $patch = $commit->get_patch( $parent, $count );
    $c->response->body($patch);
    $c->response->content_type('text/plain');
    $c->response->status(200);
}

sub snapshot : Local {
    # FIXME - implement snapshot
    Carp::croak "Not implemented.";
}

=head2 auto

Populate the header and footer. Perhaps not the best location.

=cut

sub auto : Private {
  my($self, $c) = @_;

  # XXX Move these to a plugin!
  $c->stash(
    time_since => sub {
      return 'never' unless $_[0];
      return age_string(time - $_[0]->epoch);
    },
    short_cmt => sub {
      my $cmt = shift;
      my($line) = split /\n/, $cmt;
      $line =~ s/^(.{70,80}\b).*/$1 …/;
      return $line;
    },
    abridged_description => sub {
        join(' ', grep { defined } (split / /, shift)[0..10]);
    },
  );

  # Yes, this is hideous.
  $self->header($c);
  $self->footer($c);
}

# XXX This could probably be dropped altogether.
use Gitalist::Util qw(to_utf8);
# Formally git_header_html
sub header {
  my($self, $c) = @_;

  my $title = $c->config->{sitename};

  my $project   = $c->req->param('project')  || $c->req->param('p');
  my $action    = $c->req->param('action')   || $c->req->param('a');
  my $file_name = $c->req->param('filename') || $c->req->param('f');
  if(defined $project) {
    $title .= " - " . to_utf8($project);
    if (defined $action) {
      $title .= "/$action";
      if (defined $file_name) {
        $title .= " - " . $file_name;
        if ($action eq "tree" && $file_name !~ m|/$|) {
          $title .= "/";
        }
      }
    }
  }

  $c->stash->{version}     = $Gitalist::VERSION;
  # check git's version by running it on the first project in the list.
  $c->stash->{title}       = $title;

  $c->stash->{stylesheet} = $c->config->{stylesheet} || 'gitweb.css';

  $c->stash->{project} = $project;
  my @links;
  if($project) {
    my %href_params = $self->feed_info($c);
    $href_params{'-title'} ||= 'log';

    foreach my $format qw(RSS Atom) {
      my $type = lc($format);
      push @links, {
        rel   => 'alternate',
        title => "$project - $href_params{'-title'} - $format feed",

        # XXX A bit hacky and could do with using gitweb::href() features
        href  => "?a=$type;p=$project",
        type  => "application/$type+xml"
        }, {
        rel   => 'alternate',

        # XXX This duplication also feels a bit awkward
        title => "$project - $href_params{'-title'} - $format feed (no merges)",
        href  => "?a=$type;p=$project;opt=--no-merges",
        type  => "application/$type+xml"
        };
    }
  } else {
    push @links, {
      rel => "alternate",
      title => $c->config->{sitename}." projects list",
      href => '?a=project_index',
      type => "text/plain; charset=utf-8"
      }, {
      rel => "alternate",
      title => $c->config->{sitename}." projects feeds",
      href => '?a=opml',
      type => "text/plain; charset=utf-8"
      };
  }

  $c->stash->{favicon} = $c->config->{favicon};

  # </head><body>

  $c->stash(
    logo_url      => $c->config->{logo_url},
    logo_label    => $c->config->{logo_label},
    logo_img      => $c->config->{logo},
    home_link     => $c->config->{home_link},
    home_link_str => $c->config->{home_link_str},
    );

  if (defined $project) {
      eval {
          $c->stash(Project => $c->model('GitRepos')->project($project));
      };
      if ($@) {
          $c->detach('error_404');
      }
      $c->stash(
          search_text => ( $c->req->param('s') ||
                               $c->req->param('searchtext') || ''),
          search_hash => ( $c->req->param('hb') || $c->req->param('hashbase')
                               || $c->req->param('h')  || $c->req->param('hash')
                                   || 'HEAD' ),
      );
  }
  my $a_project = $c->stash->{Project} || $c->model()->projects->[0];
  $c->stash->{git_version} = $a_project->run_cmd('--version');
}

# Formally git_footer_html
sub footer {
  my($self, $c) = @_;

  my $feed_class = 'rss_logo';

  my @feeds;
  my $project = $c->req->param('project')  || $c->req->param('p');
  if(defined $project) {
    (my $pstr = $project) =~ s[/?\.git$][];
    my $descr = $c->stash->{project_description}
            = $c->stash->{Project} ? $c->stash->{Project}->description : '';

    my %href_params = $self->feed_info($c);
    if (!%href_params) {
      $feed_class .= ' generic';
    }
    $href_params{'-title'} ||= 'log';

    @feeds = [
      map +{
        class => $feed_class,
        title => "$href_params{'-title'} $_ feed",
        href  => "/?p=$project;a=\L$_",
        name  => lc $_,
        }, qw(RSS Atom)
      ];
  } else {
    @feeds = [
      map {
        class => $feed_class,
          title => '',
          href  => "/?a=$_->[0]",
          name  => $_->[1],
        }, [opml=>'OPML'],[project_index=>'TXT'],
      ];
  }
}

# XXX This feels wrong here, should probably be refactored.
# returns hash to be passed to href to generate gitweb URL
# in -title key it returns description of link
sub feed_info {
  my($self, $c) = @_;

  my $format = shift || 'Atom';
  my %res = (action => lc($format));

  # feed links are possible only for project views
  return unless $c->req->param('project');

  # some views should link to OPML, or to generic project feed,
  # or don't have specific feed yet (so they should use generic)
  return if $c->req->param('action') =~ /^(?:tags|heads|forks|tag|search)$/x;

  my $branch;
  my $hash = $c->req->param('h')  || $c->req->param('hash');
  my $hash_base = $c->req->param('hb') || $c->req->param('hashbase');

  # branches refs uses 'refs/heads/' prefix (fullname) to differentiate
  # from tag links; this also makes possible to detect branch links
  if ((defined $hash_base && $hash_base =~ m!^refs/heads/(.*)$!) ||
    (defined $hash      && $hash      =~ m!^refs/heads/(.*)$!)) {
    $branch = $1;
  }

  # find log type for feed description (title)
  my $type = 'log';
  my $file_name = $c->req->param('f') || $c->req->param('filename');
  if (defined $file_name) {
    $type  = "history of $file_name";
    $type .= "/" if $c->req->param('action') eq 'tree';
    $type .= " on '$branch'" if (defined $branch);
  } else {
    $type = "log of $branch" if (defined $branch);
  }

  $res{-title} = $type;
  $res{'hash'} = (defined $branch ? "refs/heads/$branch" : undef);
  $res{'file_name'} = $file_name;

  return %res;
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;
    # Give project views the current HEAD.
    if ($c->stash->{Project}) {
        $c->stash->{HEAD} = $c->stash->{Project}->head_hash;
    }
}

sub error_404 :Private {
    my ($self, $c) = @_;
    $c->response->status(404);
    $c->stash(
        title => 'Page not found',
        content => 'Page not found',
    );
}

sub age_string {
	my $age = shift;
	my $age_str;

	if ($age > 60*60*24*365*2) {
		$age_str = (int $age/60/60/24/365);
		$age_str .= " years ago";
	} elsif ($age > 60*60*24*(365/12)*2) {
		$age_str = int $age/60/60/24/(365/12);
		$age_str .= " months ago";
	} elsif ($age > 60*60*24*7*2) {
		$age_str = int $age/60/60/24/7;
		$age_str .= " weeks ago";
	} elsif ($age > 60*60*24*2) {
		$age_str = int $age/60/60/24;
		$age_str .= " days ago";
	} elsif ($age > 60*60*2) {
		$age_str = int $age/60/60;
		$age_str .= " hours ago";
	} elsif ($age > 60*2) {
		$age_str = int $age/60;
		$age_str .= " min ago";
	} elsif ($age > 2) {
		$age_str = int $age;
		$age_str .= " sec ago";
	} else {
		$age_str .= " right now";
	}
	return $age_str;
}

=head1 AUTHOR

Dan Brook

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
