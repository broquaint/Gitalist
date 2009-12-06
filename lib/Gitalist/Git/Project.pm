use MooseX::Declare;

class Gitalist::Git::Project with Gitalist::Git::HasUtils {
    # FIXME, use Types::Path::Class and coerce
    use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
    use MooseX::Types::Path::Class qw/Dir/;
    use MooseX::Types::Moose qw/Str Maybe Bool HashRef ArrayRef/;
    use Moose::Autobox;
    use List::MoreUtils qw/any zip/;
    use DateTime;
    use Gitalist::Git::Object::Blob;
    use Gitalist::Git::Object::Tree;
    use Gitalist::Git::Object::Commit;
    use Gitalist::Git::Object::Tag;

    our $SHA1RE = qr/[0-9a-fA-F]{40}/;

    around BUILDARGS (ClassName $class: Dir $dir) {
        # Allows us to be called as Project->new($dir)
        # Last path component becomes $self->name
        # Full path to git objects becomes $self->path
        my $name = $dir->dir_list(-1);
        $dir = $dir->subdir('.git') if (-f $dir->file('.git', 'HEAD'));
        confess("Can't find a git repository at " . $dir)
            unless ( -f $dir->file('HEAD') );
        return $class->$orig(name => $name,
                             path => $dir);
    }

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

    has is_bare => ( isa => Bool,
                     is => 'ro',
                     lazy => 1,
                     default => sub {
                         -d $_[0]->path->parent->subdir->($_[0]->name)
                             ? 1 : 0
                         },
                     );
    has heads => ( isa => ArrayRef[HashRef],
                   is => 'ro',
                   lazy_build => 1);
    has tags => ( isa => ArrayRef[HashRef],
                   is => 'ro',
                   lazy_build => 1);
    has references => ( isa => HashRef[ArrayRef[Str]],
                        is => 'ro',
                        lazy_build => 1 );

    method BUILD {
        $self->$_() for qw/last_change owner description/; # Ensure to build early.
    }

    ## Public methods
    method head_hash (Str $head?) {
        my $output = $self->run_cmd(qw/rev-parse --verify/, $head || 'HEAD' );
        confess("No such head: " . $head) unless defined $output;

        my($sha1) = $output =~ /^($SHA1RE)$/;
        return $sha1;
    }

    method list_tree (Str $sha1?) {
        $sha1 ||= $self->head_hash;
        my $object = $self->get_object($sha1);
        return @{$object->tree};
    }

    method get_object (NonEmptySimpleStr $sha1) {
        unless ( $self->_is_valid_rev($sha1) ) {
            $sha1 = $self->head_hash($sha1);
        }
        my $type = $self->run_cmd('cat-file', '-t', $sha1);
        chomp($type);
        my $class = 'Gitalist::Git::Object::' . ucfirst($type);
        $class->new(
            project => $self,
            sha1 => $sha1,
            type => $type,
        );
    }

    method hash_by_path ($base, $path = '', $type?) {
        $path =~ s{/+$}();
        # FIXME should this really just take the first result?
        my @paths = $self->run_cmd('ls-tree', $base, '--', $path)
            or return;
        my $line = $paths[0];

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
                       NonEmptySimpleStr :$file? ) {
        $sha1 = $self->head_hash($sha1)
            if !$sha1 || $sha1 !~ $SHA1RE;

	my @search_opts;
        if ($search) {
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

        my @revs = $self->_parse_rev_list($output);

        return @revs;
    }

    method snapshot (NonEmptySimpleStr :$sha1,
                 NonEmptySimpleStr :$format
               ) {
        # TODO - only valid formats are 'tar' and 'zip'
        my $formats = { tgz => 'tar', zip => 'zip' };
        unless ($formats->exists($format)) {
            die("No such format: $format");
        }
        $format = $formats->{$format};
        my $name = $self->name;
        $name =~ s,([^/])/*\.git$,$1,;
        my $filename = $name;
        $filename .= "-$sha1.$format";
        $name =~ s/\047/\047\\\047\047/g;

        my @cmd = ('archive', "--format=$format", "--prefix=$name/", $sha1);
        return ($filename, $self->run_cmd_fh(@cmd));
        # TODO - support compressed archives
    }

    method diff ( Gitalist::Git::Object :$commit!,
                  Bool :$patch?,
                  Maybe[NonEmptySimpleStr] :$parent?,
                  NonEmptySimpleStr :$file?
              ) {
              return $commit->diff( patch => $patch,
                                    parent => $parent,
                                    file => $file);
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

    ## BUILDERS
    method _build_util {
        Gitalist::Git::Util->new(
            project => $self,
        );
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

    method _build_heads {
        my @revlines = $self->run_cmd_list(qw/for-each-ref --sort=-committerdate /, '--format=%(objectname)%00%(refname)%00%(committer)', 'refs/heads');
        my @ret;
        for my $line (@revlines) {
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

        return \@ret;
    }

    method _build_tags {
        my @revlines = $self->run_cmd_list('for-each-ref',
          '--sort=-creatordate',
          '--format=%(objectname) %(objecttype) %(refname) %(*objectname) %(*objecttype) %(subject)%00%(creator)',
	  'refs/tags'
        );
        my @ret;
        for my $line (@revlines) {
            my($refinfo, $creatorinfo) = split /\0/, $line;
	    my($rev, $type, $name, $refid, $reftype, $title) = split(' ', $refinfo, 6);
            my($creator, $epoch, $tz) = ($creatorinfo =~ /^(.*) ([0-9]+) (.*)$/);
            $name =~ s!^refs/tags/!!;

            push @ret, { sha1 => $rev, name => $name };

            #FIXME: That isn't the time I'm looking for..
            if($epoch and $tz) {
                my $dt = DateTime->from_epoch(epoch => $epoch);
                $dt->set_time_zone($tz);
                $ret[-1]->{last_change} = $dt;
            }
        }

        return \@ret;
    }

    method _build_references {
    	# 5dc01c595e6c6ec9ccda4f6f69c131c0dd945f8c refs/tags/v2.6.11
    	# c39ae07f393806ccf406ef966e9a15afc43cc36a refs/tags/v2.6.11^{}
    	my @reflist = $self->run_cmd_list(qw(show-ref --dereference))
            or return;
        my %refs;
        for (@reflist) {
            push @{$refs{$1}}, $2
                if m!^($SHA1RE)\srefs/(.*)$!;
        }

        return \%refs;
    }

    ## Private methods
    method _is_valid_rev (Str $rev) {
        return ($rev =~ /^($SHA1RE)$/);
    }

    method _parse_rev_list ($output) {
        return
            map  $self->get_gpp_object($_),
                grep $self->_is_valid_rev($_),
                    map  split(/\n/, $_, 6), split /\0/, $output;
    }

} # end class

__END__

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
=head1 ATTRIBUTES

=head2 name

The name of the Project.  By default, this is derived from the path to the git repository.

=cut
=head2 path

L<Path::Class:Dir> for the location of the git repository.

=cut
=head2 description

String containing .git/description

=cut
=head2 owner

Owner of the files on disk.

=cut
=head2 last_change

L<DateTime> for the time of the last update.
undef if the repository has never been used.

=cut
=head2 is_bare

Bool indicating whether this Project is bare.

=cut
=head2 heads

ArrayRef of hashes containing the name and sha1 of all heads.

=cut

=head2 tags

ArrayRef of hashes containing the name and sha1 of all tags.

=cut

=head2 references

Hashref of ArrayRefs for each reference.

=cut
=head1 METHODS

=head2 head_hash ($head?)

Return the sha1 for HEAD, or any specified head.

=cut
=head2 list_tree ($sha1?)

Return an array of contents for a given tree.
The tree is specified by sha1, and defaults to HEAD.
Each item is a L<Gitalist::Git::Object>.

=cut
=head2 get_object ($sha1)

Return an appropriate subclass of L<Gitalist::Git::Object> for the given sha1.

=cut
=head2 hash_by_path($sha1, $path, $type?)

Returns the sha1 for a given path, optionally limited by type.

=cut
=head2 list_revs($sha1, $count?, $skip?, \%search?, $file?)

Returns a list of revs for the given head ($sha1).

=cut
=head2 snapshot($sha1, $format)

Generate an archived snapshot of the repository.
$sha1 should be a commit or tree.
Returns a filehandle to read from.

=cut
=head2 diff($commit, $patch?, $parent?, $file?)

Generate a diff from a given L<Gitalist::Git::Object>.

=cut

=head2 reflog(@lorgargs)

Return a list of hashes representing each reflog entry.

FIXME Should this return objects?

=cut


=head1 SEE ALSO

L<Gitalist::Git::Util> L<Gitalist::Git::Object>

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
