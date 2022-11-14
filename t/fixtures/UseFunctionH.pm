package t::fixtures::UseFunctionH;

use Creature::Human;
use ExportB qw(create_cat);

# used with args
use Accessor (
    rw => [qw(want_readonly)],
);

use Deleted;

Creature::Human->dog;

my $cat = create_cat;

if (is_cat($cat)) {
    warn "nyaan";
}

1;
