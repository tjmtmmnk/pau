package Pau::Finder;
use warnings;
use strict;
use File::Find qw(find);
use Module::CoreList;
use Pau::Util;
use Smart::Args::TypeTiny qw(args args_pos);

sub get_lib_files {
    args my $class    => 'ClassName',
        my $lib_paths => 'ArrayRef[Str]',
        ;

    my $files = [];

    my $process = sub {
        my $file = $_;

        if ($file =~ /\.pm/) {
            push @$files, $file;
        }
    };

    for my $path (@$lib_paths) {
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
    args my $class    => 'ClassName',
        my $filename  => 'Str',
        my $lib_paths => 'ArrayRef[Str]',
        ;

    no strict qw(refs);

    my $pkg = $class->_filename_to_pkg($filename, $lib_paths);

    my $exports = [];
    {
        open my $fh, '>', "/dev/null";
        local *STDOUT             = $fh;
        local *STDERR             = $fh;
        local *CORE::GLOBAL::exit = sub { };
        local *CORE::GLOBAL::die  = sub { };
        $exports = $class->_exports_for_include($pkg);
    }
    return {
        package   => $pkg,
        functions => $exports,
    };
}

# from: https://metacpan.org/release/OALDERS/App-perlimports-0.000050/source/lib/App/perlimports/ExportInspector.pm#L370
sub _exports_for_include {
    args_pos my $class  => 'ClassName',
        my $module_name => 'Str',
        ;

    my $pkg     = Pau::Util->pkg_for($module_name);
    my $to_eval = <<"EOF";
package $pkg;

use Symbol::Get;
use $module_name;
our \@__EXPORTABLES;

BEGIN {
    \@__EXPORTABLES = (
        (defined Symbol::Get::get('\@$module_name\::EXPORT') ? Symbol::Get::get('\@$module_name\::EXPORT')->@* : ()),
        (defined Symbol::Get::get('\@$module_name\::EXPORT_OK') ? Symbol::Get::get('\@$module_name\::EXPORT_OK')->@* : ()),
    );
}
1;
EOF

    eval $to_eval;

    no strict 'refs';
    my $exports = [ grep { $_ !~ m{(?:BEGIN|ISA|__EXPORTABLES)} && $_ !~ m{^__ANON__} } @{ $pkg . '::__EXPORTABLES' } ];
    use strict;

    return $exports;
}

sub _filename_to_pkg {
    args_pos my $class => 'ClassName',
        my $filename   => 'Str',
        my $lib_paths  => 'ArrayRef[Str]',
        ;
    my $pkg                 = $filename;
    my $canonical_lib_paths = [ map {
            (my $path = $_) =~ s/\/$//;
            $path;
        } @$lib_paths
    ];
    my $lib_path_regex = join('|', map { $_ . '/' } @$canonical_lib_paths);
    $pkg =~ s/^($lib_path_regex)//;
    $pkg =~ s/\//::/g;
    $pkg =~ s/\.pm$//;
    return $pkg;
}

1;
