package Gitalist::Git::Serializable;

use Moose::Role;
use MooseX::Storage;

with Storage( traits => ['OnlyWhenBuilt'] );

1;
