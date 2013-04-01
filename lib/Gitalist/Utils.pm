package Gitalist::Utils;
use strict;
use warnings;
use Exporter qw/import/;

our @EXPORT_OK = qw/
    age_string
    mode_string
/;

sub age_string {
  my $age = shift;
  my $age_str;

  if ( $age > 60 * 60 * 24 * 365 * 2 ) {
    $age_str  = ( int $age / 60 / 60 / 24 / 365 );
    $age_str .= " years ago";
  }
  elsif ( $age > 60 * 60 * 24 * ( 365 / 12 ) * 2 ) {
    $age_str  = int $age / 60 / 60 / 24 / ( 365 / 12 );
    $age_str .= " months ago";
  }
  elsif ( $age > 60 * 60 * 24 * 7 * 2 ) {
    $age_str  = int $age / 60 / 60 / 24 / 7;
    $age_str .= " weeks ago";
  }
  elsif ( $age > 60 * 60 * 24 * 2 ) {
    $age_str  = int $age / 60 / 60 / 24;
    $age_str .= " days ago";
  }
  elsif ( $age > 60 * 60 * 2 ) {
    $age_str  = int $age / 60 / 60;
    $age_str .= " hours ago";
  }
  elsif ( $age > 60 * 2 ) {
    $age_str  = int $age / 60;
    $age_str .= " min ago";
  }
  elsif ( $age > 2 ) {
    $age_str  = int $age;
    $age_str .= " sec ago";
  }
  else {
    $age_str .= " right now";
  }
  return $age_str;
}

sub is_binary {
  # Crappy heuristic - does the first line or so look printable?
  return $_[0] !~ /^[[:print:]]+$ (?: \s ^[[:print:]]+$ )?/mx;
}

# via gitweb.pm circa line 1305
use Fcntl ':mode';
use constant {
    S_IFINVALID => 0030000,
    S_IFGITLINK => 0160000,
};

# submodule/subrepository, a commit object reference
sub S_ISGITLINK($) {
    return (($_[0] & S_IFMT) == S_IFGITLINK)
}

# convert file mode in octal to symbolic file mode string
sub mode_string {
    my $mode = shift;

    if (S_ISGITLINK($mode)) {
        return 'm---------';
    } elsif (S_ISDIR($mode & S_IFMT)) {
        return 'drwxr-xr-x';
    } elsif ($^O ne 'MSWin32' and S_ISLNK($mode)) { # this is ENOLINKS country, we can't stop here!
        return 'lrwxrwxrwx';
    } elsif (S_ISREG($mode)) {
        # git cares only about the executable bit
        if ($mode & S_IXUSR) {
            return '-rwxr-xr-x';
        } else {
            return '-rw-r--r--';
        }
    } else {
        return '----------';
    }
}

1;

__END__

=head1 NAME

Gitalist::Utils - trivial utils for Gitalist

=head2 FUNCTIONS

=head2 age_string

Turns an integer number of seconds into a string.

=head2 is_binary

Check whether a string is binary according to C<-B>.

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
