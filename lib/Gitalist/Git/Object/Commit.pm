package Gitalist::Git::Object::Commit;
use MooseX::Declare;

class Gitalist::Git::Object::Commit
    extends Gitalist::Git::Object
    with Gitalist::Git::Object::HasTree {
        use MooseX::Types::Moose qw/Str Int Bool Maybe ArrayRef/;
        use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
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

        method diff ( Maybe[Bool] :$patch?,
                       Maybe[NonEmptySimpleStr] :$parent?,
                       Maybe[NonEmptySimpleStr] :$file?
                   ) {
            $parent = $parent
                ? $parent
                    : $self->parents <= 1
                        ? $self->parent_sha1
                            : '-c';
            my @etc = (
                ( $file  ? ('--', $file) : () ),
            );

            my @out = $self->_raw_diff(
                ( $patch ? '--patch-with-raw' : () ),
                ( $parent ? $parent : () ),
                $self->sha1, @etc,
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

# method snapshot ( NonEmptySimpleStr $format ) {
#     # TODO - only valid formats are 'tar' and 'zip'
#     my $formats = { tgz => 'tar', zip => 'zip' };
#     unless ($formats->exists($format)) {
#         die("No such format: $format");
#     }
#     $format = $formats->{$format};
#     my $name = $self->project->name;
#     $name =~ s,([^/])/*\.git$,$1,;
#     my $filename = to_utf8($name);
#     $filename .= "-$self->sha1.$format";
#     $name =~ s/\047/\047\\\047\047/g;


#     my @cmd = ('archive', "--format=$format", "--prefix=$name/", $self->sha1);
#     return $self->_run_cmd_fh(@cmd);
#     # TODO - support compressed archives
# }

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
                @line{qw/status sim/} = $line{status} =~ /(R)(\d+)/
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

                if (/^index (\w+)\.\.(\w+) (\d+)$/) {
                    @{$ret[-1]}{qw(index src dst mode)} = ($_, $1, $2, $3);
                    next
                }

                # XXX Somewhat hacky. Ahem.
                $ret[@ret ? -1 : 0]{diff} .= "$_\n";
            }

            return @ret;
        }

    }
