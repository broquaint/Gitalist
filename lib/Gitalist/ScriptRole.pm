package Gitalist::ScriptRole;
use Moose::Role;
use MooseX::Types::Common::String qw/NonEmptySimpleStr/;
use namespace::autoclean;

has repo_dir => (
    isa => NonEmptySimpleStr, is => 'ro',
    predicate => 'has_repo_dir'
);

before 'run' => sub {
    my $self = shift;
    if ($self->has_repo_dir) {
        # FIXME - This seems gross. I should be able to pass things through
        #         to the app instance, but the params are sent to the engine
        #         and not actually used to construct the app.. Not that
        #         $ENV{GITLIST_REPO_DIR} is a bad move, just that that being
        #         the mechanism by which this works that is non optimum.
        $ENV{GITALIST_REPO_DIR} = $self->repo_dir;
    }
};

1;

