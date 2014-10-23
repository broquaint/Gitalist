package Gitalist::Controller::Root;

use Moose;
use Moose::Autobox;
use Digest::MD5 qw(md5_hex);
use Gitalist::Utils qw/ age_string mode_string /;

use namespace::autoclean;

BEGIN { extends 'Gitalist::Controller' }

__PACKAGE__->config(namespace => '');

sub root : Chained('/') PathPart('') CaptureArgs(0) {}

sub index : Chained('base') PathPart('') Args(0) {
    my ( $self, $c ) = @_;
    $c->stash( search_text => $c->req->param('s') || '' ) # FIXME - XSS?
}

# XXX Fragile much?
sub css : Chained('/root') PathPart('core.css') Args(0) {
    my ( $self, $c ) = @_;

    $c->stash( template => 'static/css/core.css', content_type => 'text/css' );
}

sub base : Chained('/root') PathPart('') CaptureArgs(0) {
  my($self, $c) = @_;

  my $git_version = `git --version`;
  chomp($git_version);
  $c->stash(
    git_version => $git_version,
    version     => $Gitalist::VERSION,

    time_since => sub {
      return 'never' unless $_[0];
      return age_string(time - $_[0]->epoch);
    },
    short_cmt => sub {
      my $cmt = shift;
      my($line) = split /\n/, $cmt;
      $line =~ s/^(.{70,80}\b).*/$1 \x{2026}/ if defined $line;
      return $line;
    },
    long_cmt => sub {
      my $cmt = shift;
      my @lines = split /\n/, $cmt;
      shift @lines;
      return join("\n", @lines);
    },
    abridged_description => sub {
        join(' ', grep { defined } (split / /, shift)[0..10]);
    },
    uri_for_gravatar => sub {
        my $email = shift;
        my $size = shift;
        my $uri = 'http://www.gravatar.com/avatar/' . md5_hex($email);
        $uri .= "?s=$size" if $size;
        return $uri;
    },
    mode_string => sub {
        return mode_string(oct shift);
    }
  );
}

sub search : Chained('base') Args(0) {}

=head2 search_help

Provides some help for the search form.

=cut

sub search_help : Chained('base') Args(0) {}

sub end : ActionClass('Serialize') {
    my ($self, $c) = @_;
    # Give repository views the current HEAD.
    if ($c->stash->{Repository}) {
        $c->stash->{HEAD} = $c->stash->{Repository}->head_hash;
    }
    if ($c->stash->{data} && blessed $c->stash->{data}) {
        $c->stash->{rest} = $c->stash->{data}->pack;
    }
}

sub error_404 : Action {
    my ($self, $c) = @_;
    $c->response->status(404);
    $c->response->body('Page not found');
}

__PACKAGE__->config(
    default => 'text/html',
    map => {
        'application/json' => [qw/ JSON /],
        map { $_ => [qw/ View Default /] }
             qw( text/css text/html text/plain
                 application/atom+xml application/rss+xml application/rss )
    },
    content_type_stash_key => 'content_type',
);

__PACKAGE__->meta->make_immutable;

__END__

=head1 NAME

Gitalist::Controller::Root - Root controller for the application

=head1 DESCRIPTION

This controller handles all of the root level paths for the application

=head1 METHODS

=head2 root

Root of chained actions

=head2 base

Populate the header and footer. Perhaps not the best location.

=head2 index

Provides the repository listing.

=head2 end

Attempt to render a view, if needed.

=head2 error_404

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
