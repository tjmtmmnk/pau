package Pau;
use Pau::Extract;
use Pau::Convert;
use Pau::Util;
use Pau::Finder;
use PPI::Token::Whitespace;
use Array::Diff;
use JSON::XS;
use File::Slurp qw(read_file);
use Try::Tiny;

use List::Util qw(first);

use constant { CACHE_FILE_FUNCTIONS => '/app/.cache/functions.json', };

# auto add and delete package
sub auto_use {
    my ($class, $filename) = @_;

    my $extractor = Pau::Extract->new($filename);

    my $current_use_statements = $extractor->get_use_statements;
    my $need_package_to_functions =
        { map { $_->{module} => $_->{functions}, } @$current_use_statements, };

    my $need_packages = $extractor->get_function_packages;

    for my $pkg (@$need_packages) {
        my $already_used = scalar $need_package_to_functions->{$pkg}->@* > 0;

        unless ($already_used) {
            $need_package_to_functions->{$pkg} = [];
        }
    }

    my $used_functions = $extractor->get_functions;

    my $last_cached_at       = Pau::Util->last_modified_at(CACHE_FILE_FUNCTIONS);
    my $max_last_modified_at = 0;

    my $lib_files = Pau::Finder->get_lib_files;

    my $stale_lib_files = [];

    for my $lib_file (@$lib_files) {
        my $last_modified_at = Pau::Util->last_modified_at($lib_file);

        my $is_stale = $last_modified_at > $last_cached_at;
        push @$stale_lib_files, $lib_file if $is_stale;

        if ($max_last_modified_at < $last_modified_at) {
            $max_last_modified_at = $last_modified_at;
        }
    }

    my $cached_pkg_to_functions = $class->_read_json_file(CACHE_FILE_FUNCTIONS) // {};

    # partial cache update
    # update only stale package
    for my $lib_file (@$stale_lib_files) {
        my $func = Pau::Finder->find_exported_function($lib_file);
        $cached_pkg_to_functions->{ $func->{package} } = $func->{functions};
    }
    $class->_create_json_file(CACHE_FILE_FUNCTIONS, $cached_pkg_to_functions);

    my $func_to_pkgs = {
        map {
            my $pkg   = $_;
            my $funcs = $cached_pkg_to_functions->{$pkg};
            map {
                $_ => $pkg,
            } @$funcs,
        } keys %$cached_pkg_to_functions,
    };

    for my $func (@$used_functions) {
        if (my $pkg = $func_to_pkgs->{$func}) {
            $need_package_to_functions->{$pkg} //= [];
            push $need_package_to_functions->{$pkg}->@*, $func;
        }
    }

    my $stmts = [];

    # sort desc to be inserted asc
    my $sorted_need_packages =
        [ sort { $b cmp $a } keys %$need_package_to_functions ];

    for my $pkg (@$sorted_need_packages) {
        my $functions =
            join(' ', sort { $a cmp $b } $need_package_to_functions->{$pkg}->@*);
        my $stmt =
            $functions eq ''
            ? "use $pkg;"
            : "use $pkg qw($functions);";
        push @$stmts, Pau::Convert->create_include_statement($stmt);
    }

    my $insert_point = $extractor->get_insert_point;
    $insert_point->add_element(PPI::Token::Whitespace->new("\n"));

    for my $stmt (@$stmts) {
        $stmt->add_element(PPI::Token::Whitespace->new("\n"));
        $insert_point->insert_after($stmt);
    }

    return $extractor->{doc}->serialize;
}

# make search more efficient by creating HashRef with key: function
sub _func_to_package {
    my ($class, $functions) = @_;
    return {
        map {
            my $package = $_->{package};
            my $funcs   = $_->{functions};
            map { $_ => $package, } @$funcs,
        } @$functions
    };
}

sub _read_json_file {
    my ($class, $filename) = @_;
    my $data = try {
        read_file($filename)
    }
    catch {
        undef;
    };
    return $data ? decode_json($data) : undef;
}

sub _create_json_file {
    my ($class, $filename, $data) = @_;
    open my $fh, '>', $filename or die qq/Can't open file "$filename" : $!/;
    print $fh encode_json($data);
    close $fh or die qq/Can't close file $filename: $!/;
}

1;
