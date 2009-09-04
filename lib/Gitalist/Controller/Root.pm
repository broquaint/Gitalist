package Gitalist::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

Gitalist::Controller::Root - Root Controller for Gitalist

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=cut

=head2 index

=cut

use IO::Capture::Stdout;
use File::Slurp qw(slurp);

sub default :Path {
  my ( $self, $c ) = @_;

  my $capture = IO::Capture::Stdout->new();
  $capture->start();
  eval {
    my $action = gitweb::main($c);
    $action->();
  };
  $capture->stop();

  gitweb::git_header_html();
  gitweb::git_footer_html();
  my $output = join '', $capture->read;
  $c->stash->{content} = $output
    unless $c->stash->{content};
  $c->stash->{template} = 'default.tt2';
}

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

  my $order = $c->req->param('order');
  if($order && $order !~ m/none|project|descr|owner|age/) {
    die "Unknown order parameter";
  }

  my @list = $c->model('Git')->projects;
  if (!@list) {
    die "No projects found";
  }

  if (-f $c->config->{home_text}) {
    print "<div class=\"index_include\">\n";
    print slurp($c->config->{home_text});
    print "</div>\n";
  }

  my $cgi;
  print $cgi->startform(-method => "get") .
    "<p class=\"projsearch\">Search:\n" .
    $cgi->textfield(-name => "s", -value => $c->req->param('searchtext')) . "\n" .
    "</p>" .
    $cgi->end_form() . "\n";

  git_project_list_body(\@list, $order);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Dan Brook,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;
