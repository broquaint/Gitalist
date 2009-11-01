use MooseX::Declare;

class Gitalist::Git::Project {
    # FIXME, use Types::Path::Class and coerce
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use DateTime;
    use Path::Class;
    use Gitalist::Git::Util;

    our $SHA1RE = qr/[0-9a-fA-F]{40}/;
    
    has name => ( isa => NonEmptySimpleStr,
                  is => 'ro' );
    has path => ( isa => "Path::Class::Dir",
                  is => 'ro');

    has description => ( isa => NonEmptySimpleStr,
                         is => 'ro',
                         lazy_build => 1,
                     );
    has owner => ( isa => NonEmptySimpleStr,
                   is => 'ro',
                   lazy_build => 1,
               );
    has last_change => ( isa => 'DateTime',
                         is => 'ro',
                         lazy_build => 1,
                     );
    has _util => ( isa => 'Gitalist::Git::Util',
                   is => 'ro',
                   lazy_build => 1,
                   handles => [ 'run_cmd' ],
               );

    method _build__util {
        my $util = Gitalist::Git::Util->new(
            gitdir => $self->path,
        );
        return $util;
    }
    
    method _build_description {
        my $description = $self->path->file('description')->slurp;
        chomp $description;
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

    method project_dir (Path::Class::Dir $project) {
        my $dir = $project->stringify;
        $dir .= '/.git'
            if -f dir($dir)->file('.git/HEAD');
        return $dir;
    }

    # Compatibility

=head2 project_info

Returns a hash containing properties of this project. The keys will
be:

	name
	description (empty if .git/description is empty/unnamed)
	owner
	last_change

=cut

    method project_info {
        return {
            name => $self->name,
            description => $self->description,
            owner => $self->owner,
            last_change => $self->last_change,
        };
    };
    
} # end class
