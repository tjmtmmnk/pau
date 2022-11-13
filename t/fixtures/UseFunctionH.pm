package t::fixtures::UseFunctionH;

use Creature::Human;

# used with args
use Accessor (
    rw => [qw(want_readonly)],
);

use Deleted;

Creature::Human->dog;

1;
