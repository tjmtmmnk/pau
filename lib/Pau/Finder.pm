package Pau::Finder;
use warnings;
use strict;
use File::Find qw(find);
use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };
use Module::CoreList;

my @lib_path_list;

BEGIN {
    $ENV{PAU_LIB_PATH_LIST} //= '';
    # assure end of path is not /
    # e.g) lib (not lib/)
    @lib_path_list = map {
        (my $path = $_) =~ s/\/$//;
        $path;
    } split(/ /, $ENV{PAU_LIB_PATH_LIST});

    no warnings 'redefine';
}

use lib @lib_path_list;

sub get_lib_files {
    my $files = [];

    my $process = sub {
        my $file = $_;

        if ($file =~ /\.pm/) {
            push @$files, $file;
        }
    };

    for my $path (@lib_path_list) {
        find(
            {
                wanted   => \&{$process},
                no_chdir => 1,
            },
            $path
        );
    }

    return $files;
}

sub find_core_module_exported_functions {
    my ($class) = @_;
    no strict qw(refs);
    my $pkgs             = [ Module::CoreList->find_modules(qr/.+/) ];
    my $pkg_to_functions = { map {
            my $pkg = $_;
            $pkg => [ @{ $pkg . '::EXPORT' }, @{ $pkg . '::EXPORT_OK' } ];
    } @$pkgs };
    return $pkg_to_functions;
}

sub find_exported_function {
    my ($class, $filename) = @_;

    no strict qw(refs);

    my $pkg = _filename_to_pkg($filename);

    {
        open my $fh, '>', "/dev/null";
        local *STDOUT             = $fh;
        local *STDERR             = $fh;
        local *CORE::GLOBAL::exit = sub { };
        local *CORE::GLOBAL::die  = sub { };
        eval "require $pkg";
    }
    return {
        package   => $pkg,
        functions => [ @{ $pkg . '::EXPORT' }, @{ $pkg . '::EXPORT_OK' } ],
    };
}

sub _filename_to_pkg {
    my $filename       = shift;
    my $pkg            = $filename;
    my $lib_path_regex = join('|', map { $_ . '/' } @lib_path_list);
    $pkg =~ s/^($lib_path_regex)//;
    $pkg =~ s/\//::/g;
    $pkg =~ s/\.pm$//;
    return $pkg;
}

1;
