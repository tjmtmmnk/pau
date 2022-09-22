package Pau::Finder;
use warnings;
use strict;

use Module::Load qw(load);

my @lib_path_list;

BEGIN {
    @lib_path_list = split( / /, $ENV{PAU_LIB_PATH_LIST} );
}
use lib @lib_path_list;

sub find_exported_functions {
    my ( $class, $filename ) = @_;

    no strict qw(refs);

    my $pkg = _filename_to_pkg($filename);

    load $pkg;
    return [ @{ $pkg . '::EXPORT' } ];
}

sub _filename_to_pkg {
    my ($filename)     = @_;
    my $pkg            = $filename;
    my $lib_path_regex = join( '|', @lib_path_list );
    $pkg =~ s/^($lib_path_regex)//;
    $pkg =~ s/\//::/g;
    $pkg =~ s/\.pm$//;
    return $pkg;
}

1;
