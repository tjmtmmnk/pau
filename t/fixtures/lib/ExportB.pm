package ExportB;

use Exporter 'import';
our @EXPORT    = qw(create_dog);
our @EXPORT_OK = qw(create_cat is_cat create_flog);

BEGIN {
    die;
}

sub create_dog {
    print 'dododo';
}

sub create_cat {
    print 'gogogo';
}

sub create_flog {
    print 'gero';
}

sub is_cat {
    1;
}

1;
