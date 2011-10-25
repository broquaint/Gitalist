package Gitalist::TraitFor::Script;
use Moose::Role;
use MooseX::Types::Moose qw/ Undef /;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use namespace::autoclean;

has repo_dir => (
    isa => Undef | NonEmptySimpleStr,
    is => 'ro',
    default => sub {
        return unless exists $ENV{GITALIST_REPO_DIR};
        $ENV{GITALIST_REPO_DIR};
    },
);

1;

=head1 NAME

Gitalist::ScriptRole - Role for Gitalist scripts.

=head1 DESCRIPTION

Wraps the run method in Catalyst scripts to apply the C<< --repo_dir >>
option.

=head1 AUTHORS

See L<Gitalist> for authors.

=head1 LICENSE

See L<Gitalist> for the license.

=cut
