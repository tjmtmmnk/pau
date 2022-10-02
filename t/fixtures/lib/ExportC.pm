package ExportB;

use Exporter 'import';
our @EXPORT    = qw(create_flog);

BEGIN {
    warn "aaa";
    exit 0;
}

sub create_flog {
    print 'gero';
}

1;
