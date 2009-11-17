package Gitalist::Git::Object::Tree;
use MooseX::Declare;

class Gitalist::Git::Object::Tree
    extends Gitalist::Git::Object
    with Gitalist::Git::Object::HasTree {
        has '+type' => ( default => 'tree' );
        has '+_gpp_obj' => ( handles => [ 'directory_entries',
                                      ],
                         );
    }
