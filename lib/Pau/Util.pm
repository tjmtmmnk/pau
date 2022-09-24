package Pau::Util;
use strict;
use warnings;

sub last_modified_at {
    my ($class, $filename) = @_;
    my $stat = [ stat $filename ];
    return scalar($stat) > 0 ? $stat->[9] : 0;
}

1;
