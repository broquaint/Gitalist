use MooseX::Declare;

class TestModelFancy with Gitalist::Git::CollectionOfRepositories {
    use MooseX::Types::Path::Class qw/Dir/;

    has fanciness => (
        is  => 'ro',
        isa => 'Bool',
    );

    has repo_dir => (
        isa      => Dir,
        is       => 'ro',
        required => 1,
        coerce   => 1,
    );

    method _build_repositories {
        [$self->get_repository('repo1')]
    }
    method _get_repo_from_name($name) {
        Gitalist::Git::Repository->new($self->repo_dir->subdir($name)->resolve);
    }
}
