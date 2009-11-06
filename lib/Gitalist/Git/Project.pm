use MooseX::Declare;

class Gitalist::Git::Project {
    # FIXME, use Types::Path::Class and coerce
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Moose qw/Str Maybe Bool/;
    use DateTime;
    use MooseX::Types::Path::Class qw/Dir/;
    use Gitalist::Git::Util;
    use aliased 'Gitalist::Git::Object';

    our $SHA1RE = qr/[0-9a-fA-F]{40}/;

    has name => ( isa => NonEmptySimpleStr,
                  is => 'ro', required => 1 );
    has path => ( isa => Dir,
                  is => 'ro', required => 1);

    has description => ( isa => Str,
                         is => 'ro',
                         lazy_build => 1,
                     );
    has owner => ( isa => NonEmptySimpleStr,
                   is => 'ro',
                   lazy_build => 1,
               );
    has last_change => ( isa => Maybe['DateTime'],
                         is => 'ro',
                         lazy_build => 1,
                     );
    has _util => ( isa => 'Gitalist::Git::Util',
                   is => 'ro',
                   lazy_build => 1,
                   handles => [ 'run_cmd' ],
               );

    has project_dir => ( isa => Dir,
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            $self->is_bare
                ? $self->path
                : $self->path->subdir('.git')
        },
    );
    has is_bare => (
        isa => Bool,
        is => 'ro',
        lazy => 1,
        default => sub {
            my $self = shift;
            -f $self->path->file('.git', 'HEAD')
                ? 0
                : -f $self->path->file('HEAD')
                    ? 1
                    : confess("Cannot find " . $self->path . "/.git/HEAD or "
                        . $self->path . "/HEAD");
        },
    );

    method BUILD {
        $self->$_() for qw/_util last_change owner description/; # Ensure to build early.
    }

    method _project_dir {
        -f $self->{path}->file('.git', 'HEAD')
            ? $self->{path}->subdir('.git')
            : $self->{path};
    }

    method _build__util {
        Gitalist::Git::Util->new(
            project => $self,
        );
    }

    method _build_description {
        my $description = "";
        eval {
            $description = $self->project_dir->file('description')->slurp;
            chomp $description;
        };
        return $description;
    }

    method _build_owner {
        my ($gecos, $name) = (getpwuid $self->project_dir->stat->uid)[6,0];
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

    use Gitalist::Git::Object;
    method get_object (Str $sha1) {
        return Gitalist::Git::Object->new(
            project => $self,
            sha1 => $sha1,
        );
    }
    
    # Should be in ::Object
    method get_object_mode_string (Gitalist::Git::Object $object) {
        return unless $object && $object->{mode};
        return $object->{modestr};
    }

    method get_object_type ($object) {
        chomp(my $output = $self->run_cmd(qw/cat-file -t/, $object));
        return unless $output;

        return $output;
    }

    method cat_file ($object) {
        my $type = $self->get_object_type($object);
        die "object `$object' is not a file\n"
            if (!defined $type || $type ne 'blob');

        my $output = $self->run_cmd(qw/cat-file -p/, $object);
        return unless $output;

        return $output;
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

} # end class
