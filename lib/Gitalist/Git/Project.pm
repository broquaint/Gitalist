use MooseX::Declare;

=head1 NAME

Gitalist::Git::Project - Model of a git repository

=head1 SYNOPSIS

    my $gitrepo = dir('/repo/base/Gitalist');
    my $project = Gitalist::Git::Project->new($gitrepo);
     $project->name;        # 'Gitalist'
     $project->path;        # '/repo/base/Gitalist/.git'
     $project->description; # 'Unnamed repository.'

=head1 DESCRIPTION

This class models a git repository, referred to in Gitalist
as a "Project".

=cut

class Gitalist::Git::Project with Gitalist::Git::HasUtils {
    # FIXME, use Types::Path::Class and coerce
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Path::Class qw/Dir/;
    use MooseX::Types::Moose qw/Str Maybe Bool HashRef/;
    use List::MoreUtils qw/any zip/;
    use DateTime;
    use aliased 'Gitalist::Git::Object';

=head1 ATTRIBUTES

=head2 name

=cut

    has name => ( isa => NonEmptySimpleStr,
                  is => 'ro', required => 1 );

=head2 path

L<Path::Class:Dir> for the location of the git repository.

=cut

    has path => ( isa => Dir,
                  is => 'ro', required => 1);

=head2 description

String containing .git/description

=cut

    has description => ( isa => Str,
                         is => 'ro',
                         lazy_build => 1,
                     );

=head2 owner

Owner of the files on disk.

=cut

    has owner => ( isa => NonEmptySimpleStr,
                   is => 'ro',
                   lazy_build => 1,
               );

=head2 last_change

L<DateTime> for the time of the last update.
undef if the repository has never been used.

=cut

    has last_change => ( isa => Maybe['DateTime'],
                         is => 'ro',
                         lazy_build => 1,
                     );

=head2 is_bare

Bool indicating whether this Project is bare.

=cut

    has is_bare => ( isa => Bool,
                     is => 'ro',
                     lazy => 1,
                     default => sub {
                         -d $_[0]->path->parent->subdir->($_[0]->name)
                             ? 1 : 0
                         },
                     );

    method BUILD {
        $self->$_() for qw/last_change owner description/; # Ensure to build early.
    }

    around BUILDARGS (ClassName $class: Dir $dir) {
        my $name = $dir->dir_list(-1);
        $dir = $dir->subdir('.git') if (-f $dir->file('.git', 'HEAD'));
        confess("Can't find a git repository at " . $dir)
            unless ( -f $dir->file('HEAD') );
        return $class->$orig(name => $name,
                             path => $dir);
    }

    method _build__util {
        Gitalist::Git::Util->new(
            project => $self,
        );
    }

    our $SHA1RE = qr/[0-9a-fA-F]{40}/;

    method _build_description {
        my $description = "";
        eval {
            $description = $self->path->file('description')->slurp;
            chomp $description;
        };
        return $description;
    }

    method _build_owner {
        my ($gecos, $name) = (getpwuid $self->path->stat->uid)[6,0];
        $gecos =~ s/,+$//;
        return length($gecos) ? $gecos : $name;
    }

    method _build_last_change {
        my $last_change;
        my $output = $self->run_cmd(
            qw{ for-each-ref --format=%(committer)
                --sort=-committerdate --count=1 refs/heads
          });
        if (my ($epoch, $tz) = $output =~ /\s(\d+)\s+([+-]\d+)$/) {
            my $dt = DateTime->from_epoch(epoch => $epoch);
            $dt->set_time_zone($tz);
            $last_change = $dt;
        }
        return $last_change;
    }

=head2 heads

Return an array containing the list of heads.

=cut

    method heads {
        my $cmdout = $self->run_cmd(qw/for-each-ref --sort=-committerdate /, '--format=%(objectname)%00%(refname)%00%(committer)', 'refs/heads');
        my @output = $cmdout ? split(/\n/, $cmdout) : ();
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

=head2 references

Return a hash of references.

=cut

    has references => ( isa => HashRef[Str], is => 'ro', lazy_build => 1 );

    method _build_references {

    	# 5dc01c595e6c6ec9ccda4f6f69c131c0dd945f8c refs/tags/v2.6.11
    	# c39ae07f393806ccf406ef966e9a15afc43cc36a refs/tags/v2.6.11^{}
    	my $cmdout = $self->run_cmd(qw(show-ref --dereference))
	    	or return;
            my @reflist = $cmdout ? split(/\n/, $cmdout) : ();
	    my %refs;
	    for(@reflist) {
		    push @{$refs{$1}}, $2
			    if m!^($SHA1RE)\srefs/(.*)$!;
	    }

	    return \%refs;
    }

=head2 head_hash

Find the hash of a given head (defaults to HEAD).

=cut

    method head_hash (Str $head?) {
        my $output = $self->run_cmd(qw/rev-parse --verify/, $head || 'HEAD' );
        return unless defined $output;

        my($sha1) = $output =~ /^($SHA1RE)$/;
        return $sha1;
    }

=head2 list_tree

Return an array of contents for a given tree.
The tree is specified by sha1, and defaults to HEAD.
The keys for each item will be:

	mode
	type
	object
	file

=cut

    method list_tree (Str $sha1?) {
        $sha1 ||= $self->head_hash;

        my $output = $self->run_cmd(qw/ls-tree -z/, $sha1);
        return unless defined $output;

        my @ret;
        for my $line (split /\0/, $output) {
            my ($mode, $type, $object, $file) = split /\s+/, $line, 4;
            push @ret, Object->new( mode => oct $mode,
                                    type => $type,
                                    sha1 => $object,
                                    file => $file,
                                    project => $self,
                                  );
        }
        return @ret;
    }

    method get_object (NonEmptySimpleStr $sha1) {
        unless ( $self->_is_valid_rev($sha1) ) {
            $sha1 = $self->head_hash($sha1);
        }
        return Object->new(
            project => $self,
            sha1 => $sha1,
        );
    }

    method _is_valid_rev (Str $rev) {
        return ($rev =~ /^($SHA1RE)$/);
    }

    # Should be in ::Object
    method get_object_mode_string (Gitalist::Git::Object $object) {
        return $object->modestr;
    }

    method get_object_type (NonEmptySimpleStr $sha1) {
        return $self->get_object($sha1)->type;
    }

    method cat_file (NonEmptySimpleStr $sha1) {
        return $self->get_object($sha1)->contents;
    }

    method hash_by_path ($base, $path?, $type?) {
        $path ||= '';
        $path =~ s{/+$}();

        my $output = $self->run_cmd('ls-tree', $base, '--', $path)
            or return;
        my($line) = $output ? split(/\n/, $output) : ();

        #'100644 blob 0fa3f3a66fb6a137f6ec2c19351ed4d807070ffa	panic.c'
        $line =~ m/^([0-9]+) (.+) ($SHA1RE)\t/;
        return defined $type && $type ne $2
            ? ()
                : $3;
    }

    method list_revs ( NonEmptySimpleStr :$sha1!,
                       Int :$count?,
                       Int :$skip?,
                       HashRef :$search?,
                       NonEmptySimpleStr :$file?
                   ) {
        $sha1 = $self->head_hash($sha1)
            if !$sha1 || $sha1 !~ $SHA1RE;

	my @search_opts;
        if($search) {
            $search->{type} = 'grep'
                if $search->{type} eq 'commit';
            @search_opts = (
                # This seems a little fragile ...
                qq[--$search->{type}=$search->{text}],
                '--regexp-ignore-case',
                $search->{regexp} ? '--extended-regexp' : '--fixed-strings'
            );
        }

        my $output = $self->run_cmd(
            'rev-list',
            '--header',
            (defined $count ? "--max-count=$count" : ()),
            (defined $skip ? "--skip=$skip"       : ()),
            @search_opts,
            $sha1,
            '--',
            ($file ? $file : ()),
        );
        return unless $output;

        my @revs = $self->parse_rev_list($output);

        return @revs;
    }

    method parse_rev_list ($output) {
        return
            map  $self->get_gpp_object($_),
                grep $self->_is_valid_rev($_),
                    map  split(/\n/, $_, 6), split /\0/, $output;
    }

    # XXX Ideally this would return a wee object instead of ad hoc structures.
    method diff ( Gitalist::Git::Object :$commit,
                  Bool :$patch?,
                  Maybe[NonEmptySimpleStr] :$parent?,
                  NonEmptySimpleStr :$file? ) {
        # Use parent if specifed, else take the parent from the commit
        # if there is only one, otherwise it was a merge commit.
        $parent = $parent
            ? $parent
            : $commit->parents <= 1
            ? $commit->parent_sha1
            : '-c';
        my @etc = (
            ( $file  ? ('--', $file) : () ),
        );

        my @out = $self->raw_diff(
            ( $patch ? '--patch-with-raw' : () ),
            ( $parent ? $parent : () ),
            $commit->sha1, @etc,
        );

        # XXX Yes, there is much wrongness having parse_diff_tree be destructive.
        my @difftree = $self->parse_diff_tree(\@out);

        return \@difftree
            unless $patch;

        # The blank line between the tree and the patch.
        shift @out;

        # XXX And no I'm not happy about having diff return tree + patch.
        return \@difftree, [$self->parse_diff(@out)];
    }

    method parse_diff (@diff) {
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

    # gitweb uses the following sort of command for diffing merges:
# /home/dbrook/apps/bin/git --git-dir=/home/dbrook/dev/app/.git diff-tree -r -M --no-commit-id --patch-with-raw --full-index --cc 316cf158df3f6207afbae7270bcc5ba0 --
# and for regular diffs
# /home/dbrook/apps/bin/git --git-dir=/home/dbrook/dev/app/.git diff-tree -r -M --no-commit-id --patch-with-raw --full-index 2e3454ca0749641b42f063730b0090e1 316cf158df3f6207afbae7270bcc5ba0 --

    method raw_diff (@args) {
        my $cmdout = $self->run_cmd(
            qw(diff-tree -r -M --no-commit-id --full-index),
            @args
        );
        return $cmdout ? split(/\n/, $cmdout) : ();
    }

    method parse_diff_tree ($diff) {
        my @keys = qw(modesrc modedst sha1src sha1dst status src dst);
        my @ret;
        while (@$diff and $diff->[0] =~ /^:\d+/) {
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

    method reflog (@logargs) {
        my @entries
            =  $self->run_cmd(qw(log -g), @logargs)
                =~ /(^commit.+?(?:(?=^commit)|(?=\z)))/msg;

#  commit 02526fc15beddf2c64798a947fecdd8d11bf993d
#  Reflog: HEAD@{14} (The Git Server <git@git.dev.venda.com>)
#  Reflog message: push
#  Author: Foo Barsby <fbarsby@example.com>
#  Date:   Thu Sep 17 12:26:05 2009 +0100
#
#      Merge branch 'abc123'

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
            }
            ;
        } @entries;
    }

    # Compatibility

=head2 info

Returns a hash containing properties of this project. The keys will
be:

	name
	description (empty if .git/description is empty/unnamed)
	owner
	last_change

=cut

    method info {
        return {
            name => $self->name,
            description => $self->description,
            owner => $self->owner,
            last_change => $self->last_change,
        };
    };

=head1 SEE ALSO

L<Gitalist::Git::Util> L<Gitalist::Git::Object>

=head1 AUTHORS AND COPYRIGHT

  Catalyst application:
    (C) 2009 Venda Ltd and Dan Brook <dbrook@venda.com>

  Original gitweb.cgi from which this was derived:
    (C) 2005-2006, Kay Sievers <kay.sievers@vrfy.org>
    (C) 2005, Christian Gierke

=head1 LICENSE

FIXME - Is this going to be GPLv2 as per gitweb? If so this is broken..

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

} # end class
