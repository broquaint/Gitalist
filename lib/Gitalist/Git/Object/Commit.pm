package Gitalist::Git::Object::Commit;
use MooseX::Declare;

class Gitalist::Git::Object::Commit
    extends Gitalist::Git::Object
    with Gitalist::Git::Object::HasTree {
        use MooseX::Types::Moose qw/Str Int Bool Maybe ArrayRef/;
        use MooseX::Types::Common::String qw/NonEmptySimpleStr SimpleStr/;
        use Moose::Autobox;
        use List::MoreUtils qw/any zip/;
        our $SHA1RE = qr/[0-9a-fA-F]{40}/;

        has '+type' => ( default => 'commit' );
        has '+_gpp_obj' => ( handles => [ 'comment',
                                          'tree_sha1',
                                          'committer',
                                          'committed_time',
                                          'author',
                                          'authored_time',
                                          'parents',
                                          'parent_sha1',
                                          'parent_sha1s',
                                      ],
                         );

        method _build_tree {
            return [$self->repository->get_object($self->tree_sha1)];
        }

        method sha_by_path ($path) {
            $path =~ s{/+$}();
            # FIXME should this really just take the first result?
            my @paths = $self->repository->run_cmd('ls-tree', $self->sha1, '--', $path)
                or return;
            my $line = $paths[0];

            #'100644 blob 0fa3f3a66fb6a137f6ec2c19351ed4d807070ffa	panic.c'
            $line =~ m/^([0-9]+) (.+) ($SHA1RE)\t/;
            my $sha1 = $3;
            return $sha1;
    }

        method get_patch ( Maybe[NonEmptySimpleStr] $parent_hash?,
                           Int $patch_count?) {
            # assembling the git command to execute...
            my @cmd = qw/format-patch --encoding=utf8 --stdout/;

            # patch, or patch set?
            push @cmd,
                defined $patch_count
                ? "-$patch_count -n" : "-1";

            # refspec
            if (defined $parent_hash) {
                #  if a parent is specified: hp..h
                push @cmd, "$parent_hash.." . $self->sha1;
            } else {
                #  if not, but a merge commit: --cc h
                #  otherwise: --root h
                push @cmd, $self->parents->length > 1
                    ? '--cc' : '--root';
                push @cmd, $self->sha1;
            }
            return $self->_run_cmd_fh( @cmd );
        }

        method diff ( Bool              :$patch?,
                      NonEmptySimpleStr :$parent?,
                      NonEmptySimpleStr :$filename?
                    ) {
            $parent = $parent
                ? $parent
                    : $self->parents <= 1
                        ? $self->parent_sha1
                            : '-c';
            my @etc = (
                ( $filename  ? ('--', $filename) : () ),
            );

            # If we're not comparing against something and we have multiple
            # parents then it's a merge commit so show what was merged.
            my $sha1 = $parent && $parent eq '-c' && @{[$self->parents]} > 1
                 ? sprintf("%s^1..%s^2", ($self->sha1) x 2)
                      : $self->sha1;

            my @out = $self->_raw_diff(
                ( $patch ? '--patch-with-raw' : () ),
                ( $parent ? $parent : () ),
                $sha1, @etc,
            );

            # XXX Yes, there is much wrongness having _parse_diff_tree be destructive.
            my @difftree = $self->_parse_diff_tree(\@out);

            return \@difftree
                unless $patch;

            # The blank line between the tree and the patch.
            shift @out;

            # XXX And no I'm not happy about having diff return tree + patch.
            return \@difftree, [$self->_parse_diff(@out)];
        }

        ## Private methods
        # gitweb uses the following sort of command for diffing merges:
        # /home/dbrook/apps/bin/git --git-dir=/home/dbrook/dev/app/.git diff-tree -r -M --no-commit-id --patch-with-raw --full-index --cc 316cf158df3f6207afbae7270bcc5ba0 --
        # and for regular diffs
        # /home/dbrook/apps/bin/git --git-dir=/home/dbrook/dev/app/.git diff-tree -r -M --no-commit-id --patch-with-raw --full-index 2e3454ca0749641b42f063730b0090e1 316cf158df3f6207afbae7270bcc5ba0 --
        method _raw_diff (@args) {
            return $self->_run_cmd_list(
                qw(diff-tree -r -M --no-commit-id --full-index),
                @args
            );
        }

        method _parse_diff_tree ($diff) {
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
                @line{qw/status sim/} = $line{status} =~ /(R)0*(\d+)/
                    if $line{status} =~ /^R/;
                push @ret, \%line;
            }

            return @ret;
        }

        method _parse_diff (@diff) {
            my @ret;
            for (@diff) {
                # This regex is a little pathological.
                if (m{^diff --git (a/(.*?)) (b/\2)}) {
                    push @ret, {
                        head => $_,
                        a    => $1,
                        b    => $3,
                        file => $2,
                        diff => '',
                    };
                    next;
                }

                if (/^index (\w+)\.\.(\w+)(?: (\d+))?$/) {
                    @{$ret[-1]}{qw(index src dst mode)} = ($_, $1, $2, $3);
                    next
                }

                # XXX Somewhat hacky. Ahem.
                $ret[@ret ? -1 : 0]{diff} .= "$_\n";
            }

            return @ret;
        }


  # XXX A prime candidate for caching.
  method blame ( NonEmptySimpleStr $filename, SimpleStr $sha1 ) {
    my @blameout = $self->_run_cmd_list(
      blame => '-p', $sha1 ? $sha1 : $self->sha1, '--', $filename
    );

    my(%commitdata, @filedata);
    while(defined(local $_ = shift @blameout)) {
      my ($sha1, $orig_lineno, $lineno, $group_size) =
        /^([0-9a-f]{40}) (\d+) (\d+)(?: (\d+))?$/;

      $commitdata{$sha1} = {}
        unless exists $commitdata{$sha1};

      my $commit = $commitdata{$sha1};
      my $line;
      until(($line = shift @blameout) =~ s/^\t//) {
        $commit->{$1} = $2
         if $line =~ /^(\S+) (.*)/;
      }

      unless(exists $commit->{author_dt}) {
        for my $t (qw/author committer/) {
          my $dt = DateTime->from_epoch(epoch => $commit->{"$t-time"});
          $dt->set_time_zone($commit->{"$t-tz"});
          $commit->{"$t\_dt"} = $dt;
        }
      }

      push @filedata, {
        line => $line,
        commit => { sha1 => $sha1, %$commit },
        meta => {
          orig_lineno => $orig_lineno,
          lineno => $lineno,
          ( $group_size ? (group_size => $group_size) : () ),
        },
      };
    }

    return \@filedata;
  }
}


1;

__END__

=head1 NAME

Gitalist::Git::Object::Commit

=head1 SYNOPSIS

    my $commit = Repository->get_object($commit_sha1);

=head1 DESCRIPTION

Represents a commit object in a git repository.
Subclass of C<Gitalist::Git::Object>.


=head1 ATTRIBUTES

=head2 committer

=head2 committed_time

=head2 author

=head2 authored_time

=head2 comment

=head2 tree_sha1

=head2 parents

=head2 parent_sha1

=head2 parent_sha1s


=head1 METHODS

=head2 sha_by_path ($path)

Returns the tree/file sha1 for a given path in a commit.

=head2 get_patch

=head2 diff

=head2 blame

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
