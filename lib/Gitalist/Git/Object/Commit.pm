package Gitalist::Git::Object::Commit;
use MooseX::Declare;

class Gitalist::Git::Object::Commit extends Gitalist::Git::Object {
    has '+_gpp_obj' => ( handles => [ 'comment',
                                      'tree_sha1',
                                      'committer',
                                      'committed_time',
                                      'author',
                                      'authored_time',
                                      'parents',
                                      'parent_sha1',
                                      'parent_sha1s',
                                  ],
                         );

}
