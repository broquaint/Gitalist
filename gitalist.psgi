use strict;
use warnings;

use Gitalist;

my $app = Gitalist->apply_default_middlewares(Gitalist->psgi_app);
$app;

