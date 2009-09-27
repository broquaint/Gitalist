package Gitalist::Model::Git;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Model' }

use DateTime;
use Path::Class;
use Carp qw/croak/;
use File::Find::Rule;
use DateTime::Format::Mail;
use File::Stat::ModeString;
use List::MoreUtils qw/any/;
use Scalar::Util qw/blessed/;

# abstraction fail - but currently needed for unit tests to work
use Gitalist;

{
	my $git;
	sub git {
		return $git
			if $git;

		if (my $config_git = Gitalist->config->{git}) {
			$git = $config_git if -x $config_git;
		}
		else {
			require File::Which;
			$git = File::Which::which('git');
		}

		if (!$git) {
			die <<EOR
Could not find a git executable.
Please specify the which git executable to use in gitweb.yml
EOR
		}

		return $git;
	}
}

sub is_git_repo {
    my ($self, $dir) = @_;

    return -f $dir->file('HEAD') || -f $dir->file('.git/HEAD');
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

    $props{owner} = (getpwuid $dir->stat->uid)[6];

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

    my $base = dir(Gitalist->config->{repo_dir});

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
            name => ($name . ( $is_bare ? '' : '/.git' )),
            $self->get_project_properties(
				$is_bare ? $obj : $obj->subdir('.git')
			),
        };
    }

    return [sort { $a->{name} cmp $b->{name} } @ret];
}

sub run_cmd {
    my ($self, @args) = @_;

    open my $fh, '-|', __PACKAGE__->git, @args
        or die "failed to run git command";
    binmode $fh, ':encoding(UTF-8)';

    my $output = do { local $/ = undef; <$fh> };
    close $fh;

    return $output;
}

sub run_cmd_in {
    my ($self, $project, @args) = @_;

    my $path;
    if (blessed($project) && $project->isa('Path::Class::Dir')) {
        $path = $project->stringify;
    }
    else {
        $path = $self->git_dir_from_project_name($project);
    }
    return $self->run_cmd('--git-dir' => $path, @args);
}

sub git_dir_from_project_name {
    my ($self, $project) = @_;

    return dir(Gitalist->config->{repo_dir})->subdir($project);
}

sub get_head_hash {
    my ($self, $project) = @_;

    my $output = $self->run_cmd_in($project, qw/rev-parse --verify HEAD/ );
    return unless defined $output;

    my ($head) = $output =~ /^([0-9a-fA-F]{40})$/;
    return $head;
}

sub list_tree {
    my ($self, $project, $rev) = @_;

    $rev ||= $self->get_head_hash($project);

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

sub cat_file {
    my ($self, $project, $object) = @_;

    my $type = $self->get_object_type($project, $object);
    die "object `$object' is not a file\n"
        if (!defined $type || $type ne 'blob');

    my $output = $self->run_cmd_in($project, qw/cat-file -p/, $object);
    return unless $output;

    return $output;
}

sub valid_rev {
    my ($self, $rev) = @_;

    return unless $rev;
    return ($rev =~ /^([0-9a-fA-F]{40})$/);
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

    $args{rev} ||= $self->get_head_hash($project);

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

sub archive {
    my ($self, $project, $rev) = @_;

    #FIXME: huge memory consuption
    #TODO: compression
    return $self->run_cmd_in($project, qw/archive --format=tar/, "--prefix=${project}/", $rev);
}

1;

__PACKAGE__->meta->make_immutable;
