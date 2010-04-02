package Gitalist::ActionRole::FilenameArgs;
use Moose::Role;
use namespace::autoclean;

requires 'execute';

before 'execute' => sub {
    my ($self, $controller, $c, @args) = @_;
    $c->stash->{filename} = join('/', @args) || ''
	 unless $c->stash->{filename};
};

1;

