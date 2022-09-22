package ExportB;

use Exporter 'import';
our @EXPORT    = qw(create_dog);
our @EXPORT_OK = qw(create_cat);

sub create_dog {
    print 'dododo';
}

sub create_cat {
    print 'gogogo';
}

1;
