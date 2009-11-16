package Gitalist::Git::Object::Tree;
use MooseX::Declare;

class Gitalist::Git::Object::Tree extends Gitalist::Git::Object {
    has '+_gpp_obj' => ( handles => [ 'directory_entries',
                                  ],
                         );
}
