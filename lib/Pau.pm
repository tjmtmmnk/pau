package Pau;
use Pau::Extract;
use Pau::Convert;
use Pau::Util;
use Pau::Finder;
use PPI::Token::Whitespace;
use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };

use List::Util qw(first);

use constant { CACHE_FILE_FUNCTIONS => '/app/.cache/functions.json', };

BEGIN {
    $ENV{DEBUG} //= 0;
}

# auto add and delete package
sub auto_use {
    my ($class, $filename) = @_;

    my $extractor = Pau::Extract->new($filename);

    my $current_use_statements = $extractor->get_use_statements;

    for my $current_inc ($extractor->get_includes->@*) {
        unless ($current_inc->pragma) {
            if ($current_inc->next_sibling->isa('PPI::Token::Whitespace')) {
                $current_inc->next_sibling->delete;
            }
            $current_inc->delete;
        }
    }

    my $need_package_to_functions =
        { map { $_->{module} => $_->{functions}, } @$current_use_statements, };

    my $need_packages = $extractor->get_function_packages;

    if ($ENV{DEBUG}) {
        p "need packages";
        p $need_packages;
    }

    for my $pkg (@$need_packages) {
        my $already_used = scalar $need_package_to_functions->{$pkg}->@* > 0;

        unless ($already_used) {
            $need_package_to_functions->{$pkg} = [];
        }
    }

    my $used_functions = $extractor->get_functions;

    if ($ENV{DEBUG}) {
        p "used functions";
        p $used_functions;
    }

    my $last_cached_at       = Pau::Util->last_modified_at(CACHE_FILE_FUNCTIONS);
    my $max_last_modified_at = 0;

    my $lib_files = Pau::Finder->get_lib_files;

    if ($ENV{DEBUG}) {
        p "lib files";
        p $lib_files;
    }

    my $stale_lib_files = [];

    for my $lib_file (@$lib_files) {
        my $last_modified_at = Pau::Util->last_modified_at($lib_file);

        my $is_stale = $last_modified_at > $last_cached_at;
        push @$stale_lib_files, $lib_file if $is_stale;

        if ($max_last_modified_at < $last_modified_at) {
            $max_last_modified_at = $last_modified_at;
        }
    }

    my $cached_pkg_to_functions = Pau::Util->read_json_file(CACHE_FILE_FUNCTIONS) // {};

    # partial cache update
    # update only stale package
    for my $lib_file (@$stale_lib_files) {
        my $func = Pau::Finder->find_exported_function($lib_file);
        $cached_pkg_to_functions->{ $func->{package} } = $func->{functions};
    }
    Pau::Util->write_json_file(CACHE_FILE_FUNCTIONS, $cached_pkg_to_functions);

    my $func_to_pkgs = {
        map {
            my $pkg   = $_;
            my $funcs = $cached_pkg_to_functions->{$pkg};
            map {
                $_ => $pkg,
            } @$funcs,
        } keys %$cached_pkg_to_functions,
    };

    if ($ENV{DEBUG}) {
        p "func to pkgs";
        p $func_to_pkgs;
    }

    for my $func (@$used_functions) {
        if (my $pkg = $func_to_pkgs->{$func}) {
            $need_package_to_functions->{$pkg} //= [];
            push $need_package_to_functions->{$pkg}->@*, $func;
        }
    }

    if ($ENV{DEBUG}) {
        p "need pkg to funcs";
        p $need_package_to_functions;
    }

    my $statements = [];

    # sort desc to be inserted asc
    my $sorted_need_packages =
        [ sort { lc($b) cmp lc($a) } keys %$need_package_to_functions ];

    for my $pkg (@$sorted_need_packages) {
        my $functions =
            join(' ', sort { lc($a) cmp lc($b) } $need_package_to_functions->{$pkg}->@*);
        my $stmt =
            $functions eq ''
            ? "use $pkg;"
            : "use $pkg qw($functions);";
        push @$statements, Pau::Convert->create_include_statement($stmt);
    }

    if ($ENV{DEBUG}) {
        p "statements";
        p $statements;
    }

    $class->_insert_statements($extractor, $statements);

    return $extractor->{doc}->serialize;
}

sub _insert_statements {
    my ($class, $extractor, $statements) = @_;

    my $insert_point = $extractor->get_insert_point;

    if (defined $insert_point) {
        $insert_point->add_element(PPI::Token::Whitespace->new("\n"));

        for my $stmt (@$statements) {
            $stmt->add_element(PPI::Token::Whitespace->new("\n"));
            $insert_point->insert_after($stmt);
        }
    } else {
        my $first_element  = $extractor->{doc}->first_element;
        my $asc_statements = [ sort { lc($a->content) cmp lc($b->content) } @$statements ];

        for my $stmt (@$asc_statements) {
            $stmt->add_element(PPI::Token::Whitespace->new("\n"));
            $first_element->insert_before($stmt);
        }
    }

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

1;
