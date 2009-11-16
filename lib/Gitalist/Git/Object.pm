use MooseX::Declare;
use Moose::Autobox;

class Gitalist::Git::Object {
    use MooseX::Types::Moose qw/Str Int Bool Maybe ArrayRef/;
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use File::Stat::ModeString qw/mode_to_string/;
    use List::MoreUtils qw/any zip/;

    our $SHA1RE = qr/[0-9a-fA-F]{40}/;

    # project and sha1 are required initargs
    has project => ( isa => 'Gitalist::Git::Project',
                     required => 1,
                     is => 'ro',
                     weak_ref => 1,
                     handles => {
                         _run_cmd => 'run_cmd',
                         _run_cmd_list => 'run_cmd_list',
                         _get_gpp_object => 'get_gpp_object',
                     },
                 );
    has sha1 => ( isa => NonEmptySimpleStr,
                  required => 1,
                  is => 'ro' );

    has $_ => ( isa => NonEmptySimpleStr,
                required => 1,
                is => 'ro',
                lazy_build => 1 )
        for qw/type modestr size/;

    has _gpp_obj => ( isa => 'Git::PurePerl::Object',
                      required => 1,
                      is => 'ro',
                      lazy_build => 1,
                  );

    # This feels wrong, but current templates assume
    # these attributes are present on every object.
    foreach my $key (qw/content/) {
        has $key => ( isa => Str,
                      required => 1,
                      is => 'ro',
                      lazy_build => 1,
                  );
        method "_build_$key" {
            confess("Object can't " . $key) unless $self->_gpp_obj->can($key);
            return $self->_gpp_obj->$key;
        }
    }

    # objects can't determine their mode or filename
    has file => ( isa => NonEmptySimpleStr,
                  required => 0,
                  is => 'ro' );
    has mode => ( isa => Int,
                  required => 1,
                  default => 0,
                  is => 'ro' );

    has tree => ( isa => 'ArrayRef[Gitalist::Git::Object]',
                  required => 0,
                  is => 'ro',
                  lazy_build => 1 );

    method BUILD { $self->$_() for qw/_gpp_obj type size modestr/ }

    method _build_tree {
        confess("Can't list_tree on a blob object.")
            if $self->type eq 'blob';
        my $output = $self->_run_cmd(qw/ls-tree -z/, $self->sha1);
        return unless defined $output;

        my @ret;
        for my $line (split /\0/, $output) {
            my ($mode, $type, $object, $file) = split /\s+/, $line, 4;
            push @ret, Gitalist::Git::Object->new( mode => oct $mode,
                                    type => $type,
                                    sha1 => $object,
                                    file => $file,
                                    project => $self->project,
                                  );
        }
        return \@ret;
    }

    method diff ( Maybe[Bool] :$patch?,
                  Maybe[NonEmptySimpleStr] :$parent?,
                  Maybe[NonEmptySimpleStr] :$file?
              ) {
        # Use parent if specifed, else take the parent from the commit
        # if there is only one, otherwise it was a merge commit.
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


## Builders
method _build__gpp_obj {
        return $self->_get_gpp_object($self->sha1)
    }

    foreach my $key (qw/ type size /) {
        method "_build_$key" {
            my $v = $self->_cat_file_with_flag(substr($key, 0, 1));
            chomp($v);
            return $v;
        }
    }

    method _build_modestr {
        my $modestr = mode_to_string($self->mode);
        return $modestr;
    }

    method _cat_file_with_flag ($flag) {
        $self->_run_cmd('cat-file', '-' . $flag, $self->{sha1})
    }

} # end class
