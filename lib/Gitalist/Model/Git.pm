package Gitalist::Model::Git;

use Moose;
use namespace::autoclean;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use Moose::Autobox;

extends 'Catalyst::Model';
with 'Catalyst::Component::InstancePerContext';

has repo_dir => ( is => 'ro', required => 1, isa => NonEmptySimpleStr );

=head1 NAME

Gitalist::Model::Git - the model for git interactions

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

use Git::PurePerl;
use Path::Class qw/dir/;
sub build_per_context_instance {
  my ( $self, $c ) = @_;

  my $app = blessed($c) || $c;
  my $model = Git::Repos->new(
    project => ([$c->req->parameters->{p} || '/']->flatten)[0],
    repo_dir => $self->repo_dir,
  );

  # This is fugly as fuck. Move Git::PurePerl construction into attribute builders..
  my ($pd, $gd) = $model->project_dir( $model->project )->resolve =~ m{((.+?)(:?/\/\.git)?$)};
  $gd .= '/.git' if ($gd !~ /\.git$/ and -d "$gd/.git");
  $model->gpp( Git::PurePerl->new(gitdir => $gd, directory => $pd) );

  return $model;
}

__PACKAGE__->meta->make_immutable;

package Git::Repos; # Better name? Split out into own file once we have a sane name.
use Moose;
use namespace::autoclean;
use DateTime;
use Path::Class;
use File::Which;
use Carp qw/croak/;
use File::Find::Rule;
use DateTime::Format::Mail;
use File::Stat::ModeString;
use List::MoreUtils qw/any zip/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/; # FIXME, use Types::Path::Class and coerce

use Git::PurePerl;

# Should these live in a separate module? Or perhaps extended Regexp::Common?
# No, should be a MooseX::Types module!!
our $SHA1RE = qr/[0-9a-fA-F]{40}/;

# These are static and only need to be setup on app start.
has repo_dir => ( isa => NonEmptySimpleStr, is => 'ro', required => 1 ); # Fixme - path::class
has git      => ( isa => NonEmptySimpleStr, is => 'ro', lazy_build => 1 );
# These are dynamic and can be different from one request to the next.
has project  => ( isa => NonEmptySimpleStr, is => 'rw');
has gpp      => ( isa => 'Git::PurePerl',   is => 'rw', lazy_build => 1 );



=head2 BUILD

=cut

sub BUILD {
    my ($self) = @_;
    $self->git; # Cause lazy value build.
    $self->repo_dir;
}

sub _build_git {
    my $git = File::Which::which('git');

    if (!$git) {
        die <<EOR;
Could not find a git executable.
Please specify the which git executable to use in gitweb.yml
EOR
    }

    return $git;
}

=head2 get_object

A wrapper for the equivalent L<Git::PurePerl> method.

=cut

sub get_object {
  my($self, $sha1) = @_;

  # We either want an object or undef, *not* an empty list.
  return $self->gpp->get_object($sha1) || undef;
}

=head2 is_git_repo

Determine whether a given directory (as a L<Path::Class::Dir> object) is a
C<git> repo.

=cut

sub is_git_repo {
  my ($self, $dir) = @_;

  return -f $dir->file('HEAD') || -f $dir->file('.git/HEAD');
}

=head2 run_cmd

Call out to the C<git> binary and return a string consisting of the output.

=cut

sub run_cmd {
  my ($self, @args) = @_;

  print STDERR 'RUNNING: ', $self->git, qq[ @args], $/;

  open my $fh, '-|', $self->git, @args
    or die "failed to run git command";
  binmode $fh, ':encoding(UTF-8)';

  my $output = do { local $/ = undef; <$fh> };
  close $fh;

  return $output;
}

=head2 project_dir

The directory under which the given project will reside i.e C<.git/..>

=cut

sub project_dir {
  my($self, $project) = @_;

  my $dir = blessed($project) && $project->isa('Path::Class::Dir')
       ? $project->stringify
       : $self->dir_from_project_name($project);

  $dir .= '/.git'
      if -f dir($dir)->file('.git/HEAD');

  return $dir;
}

=head2 run_cmd_in

Run a C<git> command in a given project and return the output as a string.

=cut

sub run_cmd_in {
  my ($self, $project, @args) = @_;

  return $self->run_cmd('--git-dir' => $self->project_dir($project), @args);
}

=head2 command

Run a C<git> command for the project specified in the C<p> parameter and
return the output as a list of strings corresponding to the lines of output.

=cut

sub command {
  my($self, @args) = @_;

  my $output = $self->run_cmd('--git-dir' => $self->project_dir($self->project), @args);

  return $output ? split(/\n/, $output) : ();
}

=head2 project_info

Returns a hash corresponding to a given project's properties. The keys will
be:

    name
    description (empty if .git/description is empty/unnamed)
    owner
    last_change

=cut

sub project_info {
  my ($self, $project) = @_;

  return {
    name => $project,
    $self->get_project_properties(
      $self->dir_from_project_name($project),
    ),
  };
}

=head2 get_project_properties

Called by C<project_info> to get a project's properties.

=cut

sub get_project_properties {
  my ($self, $dir) = @_;
  my %props;

  eval {
    $props{description} = $dir->file('description')->slurp;
    chomp $props{description};
    };

  if ($props{description} && $props{description} =~ /^Unnamed repository;/) {
    delete $props{description};
  }

  ($props{owner} = (getpwuid $dir->stat->uid)[6]) =~ s/,+$//;

  my $output = $self->run_cmd_in($dir, qw{
      for-each-ref --format=%(committer)
      --sort=-committerdate --count=1 refs/heads
      });

  if (my ($epoch, $tz) = $output =~ /\s(\d+)\s+([+-]\d+)$/) {
    my $dt = DateTime->from_epoch(epoch => $epoch);
    $dt->set_time_zone($tz);
    $props{last_change} = $dt;
  }

  return %props;
}

=head2 list_projects

For the C<repo_dir> specified in the config return an array of projects where
each item will contain the contents of L</project_info>.

=cut

sub list_projects {
    my ($self, $dir) = @_;

    my $base = dir($dir || $self->repo_dir);

    my @ret;
    my $dh = $base->open or die("Cannot open dir $base");
    while (my $file = $dh->read) {
        next if $file =~ /^.{1,2}$/;

        my $obj = $base->subdir($file);
        next unless -d $obj;
        next unless $self->is_git_repo($obj);
		# XXX Leaky abstraction alert!
		my $is_bare = !-d $obj->subdir('.git');

		my $name = (File::Spec->splitdir($obj))[-1];
        push @ret, {
            name => ($name . ( $is_bare ? '' : '/.git' )),
            $self->get_project_properties(
				$is_bare ? $obj : $obj->subdir('.git')
			),
        };
  }

  return [sort { $a->{name} cmp $b->{name} } @ret];
}

=head2 dir_from_project_name

Get the corresponding directory of a given project.

=cut

sub dir_from_project_name {
  my ($self, $project) = @_;

  return dir($self->repo_dir)->subdir($project);
}

=head2 head_hash

Find the hash of a given head (defaults to HEAD) of given (or current) project.

=cut

sub head_hash {
  my ($self, $head) = @_;

  my($output) = $self->command(qw/rev-parse --verify/, $head || 'HEAD' );
  return unless $output;

  my($sha1) = $output =~ /^($SHA1RE)$/;
  return $sha1;
}

=head2 list_tree

For a given tree sha1 return an array describing the tree's contents. Where
the keys for each item will be:

    mode
    type
    object
    file

=cut

sub list_tree {
  my ($self, $sha1) = @_;

  $sha1 = $self->head_hash($sha1)
  	if !$sha1 or $sha1 !~ $SHA1RE;

  my($output) = $self->command(qw/ls-tree -z/, $sha1);
  return
  	unless $output;

  my @ret;
  for my $line (split /\0/, $output) {
    my ($mode, $type, $object, $file) = split /\s+/, $line, 4;

    push @ret, {
      mode    => oct $mode,
      # XXX I wonder why directories always turn up as 040000 ...
      modestr => $self->get_object_mode_string({mode=>oct $mode}),
      type    => $type,
      object  => $object,
      file    => $file,
    };
  }

  return @ret;
}

=head2 get_object_mode_string

Provide a string equivalent of an octal mode e.g 0644 eq '-rw-r--r--'.

=cut

sub get_object_mode_string {
  my ($self, $object) = @_;

  return unless $object && $object->{mode};
  return mode_to_string($object->{mode});
}

=head2 get_object_type

=cut

sub get_object_type {
  my ($self, $object) = @_;

  my($output) = $self->command(qw/cat-file -t/, $object)
    or return;

  return $output;
}

=head2 cat_file

Return the contents of a given file.

=cut

sub cat_file {
  my ($self, $object) = @_;

  my $type = $self->get_object_type($object, $project);
  die "object `$object' is not a file\n"
    if (!defined $type || $type ne 'blob');

  my($output) = $self->command(qw/cat-file -p/, $object)
    or return;

  return $output;
}

=head2 hash_by_path

For a given sha1 and path find the corresponding hash. Useful for find blobs.

=cut

sub hash_by_path {
  my($self, $base, $path, $type) = @_;

  $path =~ s{/+$}();

  my($line) = $self->command('ls-tree', $base, '--', $path)
    or return;

  #'100644 blob 0fa3f3a66fb6a137f6ec2c19351ed4d807070ffa    panic.c'
  $line =~ m/^([0-9]+) (.+) ($SHA1RE)\t/;
  return defined $type && $type ne $2
    ? ()
    : $3;
}

=head2 valid_rev

Check whether a given rev is valid i.e looks like a sha1.

=cut

sub valid_rev {
  my ($self, $rev) = @_;

  return unless $rev;
  return ($rev =~ /^($SHA1RE)$/);
}

=head2 raw_diff

Provides the raw output of a diff.

=cut

# gitweb uses the following sort of command for diffing merges:
# /home/dbrook/apps/bin/git --git-dir=/home/dbrook/dev/app/.git diff-tree -r -M --no-commit-id --patch-with-raw --full-index --cc 316cf158df3f6207afbae7270bcc5ba0 --
# and for regular diffs
# /home/dbrook/apps/bin/git --git-dir=/home/dbrook/dev/app/.git diff-tree -r -M --no-commit-id --patch-with-raw --full-index 2e3454ca0749641b42f063730b0090e1 316cf158df3f6207afbae7270bcc5ba0 --

sub raw_diff {
  my ($self, @args) = @_;

  return $self->command(
      qw(diff-tree -r -M --no-commit-id --full-index),
      @args
  );
}

=pod
diff --git a/TODO b/TODO
index 6a05e77..2071fd0 100644
--- a/TODO
+++ b/TODO
@@ -2,4 +2,3 @@
 * An action to find what branches have been merged, either as a list or through a search mechanism.
 * An action to find which branches a given commit is on.
 * Fix any not text/html bits e.g the patch action.
-* Simplify the creation of links.
diff --git a/lib/Gitalist/Controller/Root.pm b/lib/Gitalist/Controller/Root.pm
index 706d024..7fac165 100644
--- a/lib/Gitalist/Controller/Root.pm
+++ b/lib/Gitalist/Controller/Root.pm
@@ -157,23 +157,6 @@ sub shortlog : Local {
   );
 }
 
-=head2 tree
-
-The tree of a given commit.
=cut

=head2 diff

Returns a list of diff chunks corresponding to the files contained in the diff
and some associated metadata.

=cut

# XXX Ideally this would return a wee object instead of ad hoc structures.
sub diff {
  my($self, %args) = @_;

  # So either a parent is specifed, or we use the commit's parent if there's
  # only one, otherwise it was a merge commit.
  my $parent = $args{parent}
             ? $args{parent}
             : @{$args{commit}->parents} <= 1
               ? $args{commit}->parent_sha1
               : '-c';
  my @etc = (
    ( $args{file}  ? ('--', $args{file}) : () ),
  );

  my @out = $self->raw_diff(
    ( $args{patch} ? '--patch-with-raw' : () ),
      $parent, $args{commit}->sha1, @etc
  );

  # XXX Yes, there is much wrongness having parse_diff_tree be destructive.
  my @difftree = $self->parse_diff_tree(\@out);

  return \@difftree
    unless $args{patch};

  # The blank line between the tree and the patch.
  shift @out;

  # XXX And no I'm not happy about having diff return tree + patch.
  return \@difftree, [$self->parse_diff(@out)];
}

sub parse_diff {
  my($self, @diff) = @_;

  my @ret;
  for (@diff) {
    # This regex is a little pathological.
    if(m{^diff --git (a/(.*?)) (b/\2)}) {
      push @ret, {
        head => $_,
        a    => $1,
        b    => $3,
        file => $2,
        diff => '',
      };
      next;
    }
  
    if(/^index (\w+)\.\.(\w+) (\d+)$/) {
      @{$ret[-1]}{qw(index src dst mode)} = ($_, $1, $2, $3);
      next
    }
  
    # XXX Somewhat hacky. Ahem.
    $ret[@ret ? -1 : 0]{diff} .= "$_\n";
  }

  return @ret;
}

# $ git diff-tree -r --no-commit-id -M b222ff0a7260cc1777c7e455dfcaf22551a512fc 7e54e579e196c6c545fee1030175f65a111039d4
# :100644 100644 6a85d6c6315b55a99071974eb6ce643aeb2799d6 44c03ed6c328fa6de4b1d9b3f19a3de96b250370 M      templates/blob.tt2

=head2 parse_diff_tree

Given a L<Git::PurePerl> commit object return a list of hashes corresponding
to the C<diff-tree> output.

=cut

sub parse_diff_tree {
  my($self, $diff) = @_;

  my @keys = qw(modesrc modedst sha1src sha1dst status src dst);
  my @ret;
  while(@$diff and $diff->[0] =~ /^:\d+/) {
    my $line = shift @$diff;
    # see. man git-diff-tree for more info
    # mode src, mode dst, sha1 src, sha1 dst, status, src[, dst]
    my @vals = $line =~ /^:(\d+) (\d+) ($SHA1RE) ($SHA1RE) ([ACDMRTUX]\d*)\t([^\t]+)(?:\t([^\n]+))?$/;
    my %line = zip @keys, @vals;
    # Some convenience keys
    $line{file}   = $line{src};
    $line{sha1}   = $line{sha1dst};
    $line{is_new} = $line{sha1src} =~ /^0+$/
        if $line{sha1src};
    @line{qw/status sim/} = $line{status} =~ /(R)(\d+)/
      if $line{status} =~ /^R/;
    push @ret, \%line;
  }

  return @ret;
}

=head2 parse_rev_list

Given the output of the C<rev-list> command return a list of hashes.

=cut

sub parse_rev_list {
  my ($self, $output) = @_;

  return
    map  $self->get_object($_),
    grep $self->valid_rev($_),
    map  split(/\n/, $_, 6), split /\0/, $output;
}

=head2 list_revs

Calls the C<rev-list> command (a low-level from of C<log>) and returns an
array of hashes.

=cut

sub list_revs {
  my ($self, %args) = @_;

  $args{sha1} = $self->head_hash($args{sha1})
    if !$args{sha1} || $args{sha1} !~ $SHA1RE;

	my @search_opts;
  if($args{search}) {
    my $sargs = $args{search};
    $sargs->{type} = 'grep'
      if $sargs->{type} eq 'commit';
    @search_opts = (
       # This seems a little fragile ...
       qq[--$sargs->{type}=$sargs->{text}],
       '--regexp-ignore-case',
       $sargs->{regexp} ? '--extended-regexp' : '--fixed-strings'
    );
  }

  my $output = $self->run_cmd_in($args{project} || $self->project, 'rev-list',
    '--header',
    (defined $args{ count  } ? "--max-count=$args{count}" : ()),
    (defined $args{ skip   } ? "--skip=$args{skip}"       : ()),
    @search_opts,
    $args{sha1},
    '--',
    ($args{file} ? $args{file} : ()),
  );
  return unless $output;

  my @revs = $self->parse_rev_list($output);

  return @revs;
}

=head2 rev_info

Get a single piece of revision information for a given sha1.

=cut

sub rev_info {
  my($self, $rev, $project) = @_;

  return unless $self->valid_rev($rev);

  return $self->list_revs(
      rev => $rev, count => 1,
      ( $project ? (project => $project) : () )
  );
}

=head2 reflog

Calls the C<reflog> command and returns a list of hashes.

=cut

sub reflog {
  my ($self, @logargs) = @_;

  my @entries
    =  $self->run_cmd_in($self->project, qw(log -g), @logargs)
    =~ /(^commit.+?(?:(?=^commit)|(?=\z)))/msg;

=pod
  commit 02526fc15beddf2c64798a947fecdd8d11bf993d
  Reflog: HEAD@{14} (The Git Server <git@git.dev.venda.com>)
  Reflog message: push
  Author: Foo Barsby <fbarsby@example.com>
  Date:   Thu Sep 17 12:26:05 2009 +0100

      Merge branch 'abc123'
=cut

  return map {

    # XXX Stuff like this makes me want to switch to Git::PurePerl
    my($sha1, $type, $author, $date)
      = m{
          ^ commit \s+ ($SHA1RE)$
          .*?
          Reflog[ ]message: \s+ (.+?)$ \s+
          Author: \s+ ([^<]+) <.*?$ \s+
          Date: \s+ (.+?)$
        }xms;

    pos($_) = index($_, $date) + length $date;

    # Yeah, I just did that.

    my($msg) = /\G\s+(\S.*)/sg;

    {
      hash    => $sha1,
      type    => $type,
      author  => $author,

      # XXX Add DateTime goodness.
      date    => $date,
      message => $msg,
    };
  } @entries;
}

=head2 heads

Returns an array of hashes representing the heads (aka branches) for the
given, or current, project.

=cut

sub heads {
  my ($self, $project) = @_;

  my @output = $self->command(qw/for-each-ref --sort=-committerdate /, '--format=%(objectname)%00%(refname)%00%(committer)', 'refs/heads');

  my @ret;
  for my $line (@output) {
    my ($rev, $head, $commiter) = split /\0/, $line, 3;
    $head =~ s!^refs/heads/!!;

    push @ret, { sha1 => $rev, name => $head };

    #FIXME: That isn't the time I'm looking for..
    if (my ($epoch, $tz) = $line =~ /\s(\d+)\s+([+-]\d+)$/) {
      my $dt = DateTime->from_epoch(epoch => $epoch);
      $dt->set_time_zone($tz);
      $ret[-1]->{last_change} = $dt;
    }
  }

  return @ret;
}

=head2 refs_for

For a given sha1 check which branches currently point at it.

=cut

sub refs_for {
    my($self, $sha1) = @_;

    my $refs = $self->references->{$sha1};

    return $refs ? @$refs : ();
}

=head2 references

A wrapper for C<git show-ref --dereference>. Based on gitweb's
C<git_get_references>.

=cut

sub references {
    my($self) = @_;

    return $self->{references}
        if $self->{references};

    # 5dc01c595e6c6ec9ccda4f6f69c131c0dd945f8c refs/tags/v2.6.11
    # c39ae07f393806ccf406ef966e9a15afc43cc36a refs/tags/v2.6.11^{}
    my @reflist = $self->command(qw(show-ref --dereference))
        or return;

    my %refs;
    for(@reflist) {
        push @{$refs{$1}}, $2
            if m!^($SHA1RE)\srefs/(.*)$!;
    }

    return $self->{references} = \%refs;
}

1;

__PACKAGE__->meta->make_immutable;
