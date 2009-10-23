package Gitalist::Model::Git;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Model' }

use DateTime;
use Path::Class;
use File::Which;
use Carp qw/croak/;
use File::Find::Rule;
use DateTime::Format::Mail;
use File::Stat::ModeString;
use List::MoreUtils qw/any/;
use Scalar::Util qw/blessed/;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/; # FIXME, use Types::Path::Class and coerce

# Should these live in a separate module? Or perhaps extended Regexp::Common?
our $SHA1RE = qr/[0-9a-fA-F]{40}/;

has project  => ( isa => NonEmptySimpleStr, is => 'rw');
has repo_dir => ( isa => NonEmptySimpleStr, is => 'ro', lazy_build => 1 ); # Fixme - path::class
has git      => ( isa => NonEmptySimpleStr, is => 'ro', lazy_build => 1 );
 
sub BUILD {
    my ($self) = @_;
    $self->git; # Cause lazy value build.
    $self->repo_dir;
}

use Git::PurePerl;

has gpp => (
 #isa => 'Git::PurePerl'
  is       => 'ro',
  required => 1,
  lazy     => 1,
  default  => sub {
    my($self) = @_;
    return Git::PurePerl->new(
      directory => $self->project_dir( $self->project )
    );
  },
);

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
 
sub _build_repo_dir {
  return Gitalist->config->{repo_dir};
}

sub get_object {
  $_[0]->gpp->get_object($_[1]);
}

sub is_git_repo {
  my ($self, $dir) = @_;

  return -f $dir->file('HEAD') || -f $dir->file('.git/HEAD');
}

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

sub project_dir {
  my($self, $project) = @_;

  my $dir = blessed($project) && $project->isa('Path::Class::Dir')
       ? $project->stringify
       : $self->git_dir_from_project_name($project);

  $dir =~ s/\.git$//;

  return $dir;
}

sub run_cmd_in {
  my ($self, $project, @args) = @_;

  return $self->run_cmd('--git-dir' => $self->project_dir($project)."/.git", @args);
}

sub command {
  my($self, @args) = @_;

  my $output = $self->run_cmd('--git-dir' => $self->project_dir($self->project)."/.git", @args);

  return $output ? split(/\n/, $output) : ();
}

sub project_info {
  my ($self, $project) = @_;

  return {
    name => $project,
    $self->get_project_properties(
      $self->git_dir_from_project_name($project),
      ),
    };
}

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

sub list_projects {
  my ($self) = @_;

  my $base = dir($self->repo_dir);

  my @ret;
  my $dh = $base->open;
  while (my $file = $dh->read) {
    next if $file =~ /^.{1,2}$/;

    my $obj = $base->subdir($file);
    next unless -d $obj;
    next unless $self->is_git_repo($obj);

    # XXX Leaky abstraction alert!
    my $is_bare = !-d $obj->subdir('.git');

    my $name = (File::Spec->splitdir($obj))[-1];
    push @ret, {
      name => ($name . ( $is_bare ? '.git' : '/.git' )),
      $self->get_project_properties(
        $is_bare ? $obj : $obj->subdir('.git')
        ),
      };
  }

  return [sort { $a->{name} cmp $b->{name} } @ret];
}

sub git_dir_from_project_name {
  my ($self, $project) = @_;

  return dir($self->repo_dir)->subdir($project);
}

sub head_hash {
  my ($self, $project) = @_;

  my $output = $self->run_cmd_in($project || $self->project, qw/rev-parse --verify HEAD/ );
  return unless defined $output;

  my ($head) = $output =~ /^($SHA1RE)$/;
  return $head;
}

sub list_tree {
  my ($self, $project, $rev) = @_;

  $rev ||= $self->head_hash($project);

  my $output = $self->run_cmd_in($project, qw/ls-tree -z/, $rev);
  return unless defined $output;

  my @ret;
  for my $line (split /\0/, $output) {
    my ($mode, $type, $object, $file) = split /\s+/, $line, 4;

    push @ret, {
      mode   => oct $mode,
      type   => $type,
      object => $object,
      file   => $file,
      };
  }

  return @ret;
}

sub get_object_mode_string {
  my ($self, $object) = @_;

  return unless $object && $object->{mode};
  return mode_to_string($object->{mode});
}

sub get_object_type {
  my ($self, $project, $object) = @_;

  my $output = $self->run_cmd_in($project, qw/cat-file -t/, $object);
  return unless $output;

  chomp $output;
  return $output;
}

sub hash_by_path {
  my($self, $base, $path, $type) = @_;

  $path =~ s{/+$}();

  my($line) = $self->command('ls-tree', $base, '--', $path)
    or return;

  #'100644 blob 0fa3f3a66fb6a137f6ec2c19351ed4d807070ffa	panic.c'
  $line =~ m/^([0-9]+) (.+) ($SHA1RE)\t/;
  return defined $type && $type ne $2
    ? ()
    : $3;
}

sub cat_file {
  my ($self, $object) = @_;

  my $type = $self->get_object_type($self->project, $object);
  die "object `$object' is not a file\n"
    if (!defined $type || $type ne 'blob');

  my $output = $self->run_cmd_in($self->project, qw/cat-file -p/, $object);
  return unless $output;

  return $output;
}

sub valid_rev {
  my ($self, $rev) = @_;

  return unless $rev;
  return ($rev =~ /^($SHA1RE)$/);
}

sub diff {
  my ($self, $project, @revs) = @_;

  croak("Gitalist::Model::Git::diff needs a project and either one or two revisions")
    if scalar @revs < 1
      || scalar @revs > 2
      || any { !$self->valid_rev($_) } @revs;

  my $output = $self->run_cmd_in($project, 'diff', @revs);
  return unless $output;

  return $output;
}

{
  my $formatter = DateTime::Format::Mail->new;

  sub parse_rev_list {
    my ($self, $output) = @_;
    my @ret;

    my @revs = split /\0/, $output;

    for my $rev (split /\0/, $output) {
      for my $line (split /\n/, $rev, 6) {
        chomp $line;
        next unless $line;

        if ($self->valid_rev($line)) {
          push @ret, {rev => $line};
          next;
        }

        if (my ($key, $value) = $line =~ /^(tree|parent)\s+(.*)$/) {
          $ret[-1]->{$key} = $value;
          next;
        }

        if (my ($key, $value, $epoch, $tz) = $line =~ /^(author|committer)\s+(.*)\s+(\d+)\s+([+-]\d+)$/) {
          $ret[-1]->{$key} = $value;
          eval {
            $ret[-1]->{ $key . "_datetime" } = DateTime->from_epoch(epoch => $epoch);
            $ret[-1]->{ $key . "_datetime" }->set_time_zone($tz);
            $ret[-1]->{ $key . "_datetime" }->set_formatter($formatter);
            };

          if ($@) {
            $ret[-1]->{ $key . "_datetime" } = "$epoch $tz";
          }

          if (my ($name, $email) = $value =~ /^([^<]+)\s+<([^>]+)>$/) {
            $ret[-1]->{ $key . "_name"  } = $name;
            $ret[-1]->{ $key . "_email" } = $email;
          }
        }

        $line =~ s/^\n?\s{4}//;
        $ret[-1]->{longmessage} = $line;
        $ret[-1]->{message} = (split /\n/, $line, 2)[0];
      }
    }

    return @ret;
  }
}

sub list_revs {
  my ($self, $project, %args) = @_;

  $args{rev} ||= $self->head_hash($project);

  my $output = $self->run_cmd_in($project, 'rev-list',
    '--header',
    (defined $args{ count } ? "--max-count=$args{count}" : ()),
    (defined $args{ skip  } ? "--skip=$args{skip}"     : ()),
    $args{rev},
    '--',
    ($args{file} || ()),
    );
  return unless $output;

  my @revs = $self->parse_rev_list($output);

  return \@revs;
}

sub rev_info {
  my ($self, $project, $rev) = @_;

  return unless $self->valid_rev($rev);

  return $self->list_revs($project, rev => $rev, count => 1);
}

sub reflog {
  my ($self, @logargs) = @_;

  my @entries
    =  $self->run_cmd_in($self->project, qw(log -g), @logargs)
    =~ /(^commit.+?(?:(?=^commit)|(?=\z)))/msg;

=begin

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

sub get_heads {
  my ($self, $project) = @_;

  my $output = $self->run_cmd_in($project, qw/for-each-ref --sort=-committerdate /, '--format=%(objectname)%00%(refname)%00%(committer)', 'refs/heads');
  return unless $output;

  my @ret;
  for my $line (split /\n/, $output) {
    my ($rev, $head, $commiter) = split /\0/, $line, 3;
    $head =~ s!^refs/heads/!!;

    push @ret, { rev => $rev, name => $head };

    #FIXME: That isn't the time I'm looking for..
    if (my ($epoch, $tz) = $output =~ /\s(\d+)\s+([+-]\d+)$/) {
      my $dt = DateTime->from_epoch(epoch => $epoch);
      $dt->set_time_zone($tz);
      $ret[-1]->{last_change} = $dt;
    }
  }

  return \@ret;
}

=head2 refs_for

Return a list of refs (e.g branches) for a given sha1.

=cut

sub refs_for {
	my($self, $sha1) = @_;

	my $refs = $self->references->{$sha1};

	return $refs ? @$refs : ();
}

=head2

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

=begin

$ git diff-tree -r --no-commit-id -M b222ff0a7260cc1777c7e455dfcaf22551a512fc 7e54e579e196c6c545fee1030175f65a111039d4
:100644 100644 8976ebc7df65475b3def53a1653533c3f61070d0 852b6e170f1bad1fbd9930d3178dda8fdf1feae7 M      TODO
:100644 100644 75f5e5f9ed10ae82a960fde77ecf138159c37610 7f54f8c3a4ad426f6889b13cfba5f5ad9969e3c6 M      lib/Gitalist/Controller/Root.pm
:100644 100644 2c65caa46b56302502b9e6eef952b6f379c71fee e418acf5f7b5f771b0b2ef8be784e8dcd60a4271 M      lib/Gitalist/View/Default.pm
:000000 100644 0000000000000000000000000000000000000000 642599f9ccfc4dbc7034987ad3233655010ff348 A      lib/Gitalist/View/SyntaxHighlight.pm
:000000 100644 0000000000000000000000000000000000000000 3d2e533c41f01276b6f844bae98297273b38dffc A      root/static/css/syntax-dark.css
:100644 100644 6a85d6c6315b55a99071974eb6ce643aeb2799d6 44c03ed6c328fa6de4b1d9b3f19a3de96b250370 M      templates/blob.tt2

=cut

use List::MoreUtils qw(zip);
# XXX Hrm, getting called twice, not sure why.
sub diff_tree {
	my($self, $commit) = @_;

	my @dtout = $self->command(
		# XXX should really deal with multple parents ...
		qw(diff-tree -r --no-commit-id -M), $commit->parent_sha1, $commit->sha1
	);

	my @keys = qw(modesrc modedst sha1src sha1dst status src dst);
	my @difftree = map {
		# see. man git-diff-tree for more info
		# mode src, mode dst, sha1 src, sha1 dst, status, src[, dst]
		my @vals = /^:(\d+) (\d+) ($SHA1RE) ($SHA1RE) ([ACDMRTUX])\t([^\t]+)(?:\t([^\n]+))?$/;
		my %line = zip @keys, @vals;
		# Some convenience keys
		$line{file}   = $line{src};
		$line{sha1}   = $line{sha1dst};
		$line{is_new} = $line{sha1src} =~ /^0+$/;
		\%line;
	} @dtout;

	return @difftree;
}

sub archive {
  my ($self, $project, $rev) = @_;

  #FIXME: huge memory consuption
  #TODO: compression
  return $self->run_cmd_in($project, qw/archive --format=tar/, "--prefix=${project}/", $rev);
}

1;

__PACKAGE__->meta->make_immutable;
