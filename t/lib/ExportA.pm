package ExportA;

use Exporter 'import';
our @EXPORT    = qw(create_animal);
our @EXPORT_OK = qw(create_human);

sub create_animal {
    print 'dododo';
}

sub create_human {
    print 'gogogo';
}

1;
