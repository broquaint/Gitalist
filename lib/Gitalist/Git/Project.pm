use MooseX::Declare;

class Gitalist::Git::Project {
    # FIXME, use Types::Path::Class and coerce
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Moose qw/Str Maybe/;
    use DateTime;
    use Path::Class;
    use Gitalist::Git::Util;
    use aliased 'Gitalist::Git::Object';

    our $SHA1RE = qr/[0-9a-fA-F]{40}/;
    
    has name => ( isa => NonEmptySimpleStr,
                  is => 'ro', required => 1 );
    has path => ( isa => "Path::Class::Dir",
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

    method BUILD {
        $self->$_() for qw/_util last_change owner description/; # Ensure to build early.
    }

    method _build__util {
        my $util = Gitalist::Git::Util->new(
            gitdir => $self->project_dir($self->path),
        );
        return $util;
    }
    
    method _build_description {
        my $description = "";
        eval {
            $description = $self->path->file('description')->slurp;
            chomp $description;
        };
        return $description;
    }

    method _build_owner {
        my $owner = (getpwuid $self->path->stat->uid)[6];
        $owner =~ s/,+$//;
        return $owner;
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

    # FIXME - Why not just stay in Path::Class land and return a P::C::D here?
    method project_dir {
        my $dir = $self->path->stringify;
        $dir .= '/.git'
            if -f dir($dir)->file('.git/HEAD');
        return $dir;
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
