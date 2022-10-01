package Pau::Finder;
use warnings;
use strict;
use File::Find qw(find);
use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };
use Module::Load qw(load);

my @lib_path_list;

BEGIN {
    # assure end of path is not /
    # e.g) lib (not lib/)
    @lib_path_list = map {
        ( my $path = $_ ) =~ s/\/$//;
        $path;
    } split( / /, $ENV{PAU_LIB_PATH_LIST} );
}

use lib @lib_path_list;

sub get_lib_files {
    my $files = [];

    sub process {
        my $file = $_;

        if ( $file =~ /\.pm/ ) {
            push @$files, $file;
        }
    }

    for my $path (@lib_path_list) {
        find(
            {
                wanted   => \&process,
                no_chdir => 1,
            },
            $path
        );
    }

    return $files;
}

sub find_exported_function {
    my ( $class, $filename ) = @_;

    no strict qw(refs);

    my $pkg = _filename_to_pkg($filename);

    eval "require $pkg";
    return {
        package   => $pkg,
        functions => [ @{ $pkg . '::EXPORT' }, @{ $pkg . '::EXPORT_OK' } ],
    };
}

sub _filename_to_pkg {
    my $filename       = shift;
    my $pkg            = $filename;
    my $lib_path_regex = join( '|', map { $_ . '/' } @lib_path_list );
    $pkg =~ s/^($lib_path_regex)//;
    $pkg =~ s/\//::/g;
    $pkg =~ s/\.pm$//;
    return $pkg;
}

1;
