package Pau;
use Pau::Extract;
use Pau::Convert;
use Pau::Util;
use Pau::Finder;
use PPI::Token::Whitespace;
use List::Util qw(uniq);
use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };

use List::Util qw(first);

use constant {
    CACHE_FILE_FUNCTIONS             => '/app/.cache/functions.json',
    CACHE_FILE_CORE_MODULE_FUNCTIONS => '/app/.cache/core-functions.json',
};

BEGIN {
    $ENV{DEBUG} //= 0;
}

# auto add and delete package
sub auto_use {
    my ($class, $source) = @_;

    my $extractor = Pau::Extract->new($source);

    my $current_use_statements        = $extractor->get_use_statements;
    my $current_pkg_to_use_statements = { map {
            $_->{module} => $_
    } @$current_use_statements };

    my $need_package_to_functions = {};

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

    my $lib_files = Pau::Finder->get_lib_files;

    if ($ENV{DEBUG}) {
        p "lib files";
        p $lib_files;
    }

    my $pkg_to_functions = {};

    if ($ENV{NO_CACHE}) {
        my $core_pkg_to_functions = Pau::Finder->find_core_module_exported_functions;
        $pkg_to_functions = {%$core_pkg_to_functions};

        for my $lib_file (@$lib_files) {
            my $func = Pau::Finder->find_exported_function($lib_file);
            $pkg_to_functions->{ $func->{package} } = $func->{functions};
        }
    }
    else {
        my $cached_pkg_to_functions = Pau::Util->read_json_file(CACHE_FILE_FUNCTIONS) // {};
        $pkg_to_functions = {%$cached_pkg_to_functions};

        my $cached_core_pkg_to_functions      = Pau::Util->read_json_file(CACHE_FILE_CORE_MODULE_FUNCTIONS);
        my $should_save_core_pkg_to_functions = !defined $cached_core_pkg_to_functions;

        $cached_core_pkg_to_functions //= Pau::Finder->find_core_module_exported_functions;
        $pkg_to_functions = { %$pkg_to_functions, %$cached_core_pkg_to_functions };

        my $last_cached_at  = Pau::Util->last_modified_at(CACHE_FILE_FUNCTIONS);
        my $stale_lib_files = [];

        for my $lib_file (@$lib_files) {
            my $last_modified_at = Pau::Util->last_modified_at($lib_file);

            my $is_stale = $last_modified_at > $last_cached_at;
            push @$stale_lib_files, $lib_file if $is_stale;
        }
        # partial cache update
        # update only stale package
        for my $lib_file (@$stale_lib_files) {
            my $func = Pau::Finder->find_exported_function($lib_file);
            $pkg_to_functions->{ $func->{package} } = $func->{functions};
        }

        my $should_save_pkg_to_functions = scalar(@$stale_lib_files) > 0;
        Pau::Util->write_json_file(CACHE_FILE_FUNCTIONS,             $pkg_to_functions)             if $should_save_pkg_to_functions;
        Pau::Util->write_json_file(CACHE_FILE_CORE_MODULE_FUNCTIONS, $cached_core_pkg_to_functions) if $should_save_core_pkg_to_functions;
    }

    my $func_to_pkgs = {
        map {
            my $pkg   = $_;
            my $funcs = $pkg_to_functions->{$pkg};
            map {
                $_ => $pkg,
            } @$funcs,
        } keys %$pkg_to_functions,
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
        if (my $current_use_stmt = $current_pkg_to_use_statements->{$pkg}) {
            $current_use_stmt->{using} = 1;
        } else {
            my $functions =
                join(' ', sort { lc($a) cmp lc($b) } uniq $need_package_to_functions->{$pkg}->@*);
            my $stmt =
                $functions eq ''
                ? "use $pkg;"
                : "use $pkg qw($functions);";
            push @$statements, Pau::Convert->create_include_statement($stmt);
        }
    }

    my $unused_current_use_stmts = [ grep { !$_->{using} } @$current_use_statements ];

    for my $unused_use_stmt (@$unused_current_use_stmts) {
        my $do_not_delete = grep { $_ eq $unused_use_stmt->{module} } split(/ /, $ENV{DO_NOT_DELETE});

        unless ($do_not_delete) {
            $class->_delete_use_statement($unused_use_stmt->{stmt});
        }
    }

    if ($ENV{DEBUG}) {
        p "statements";
        p $statements;
    }

    $class->_insert_statements($extractor, $statements);

    return $extractor->{doc}->serialize;
}

sub _delete_use_statement {
    my ($class, $use_stmt) = @_;

    my $prev_sibling = $use_stmt->previous_sibling;

    while ($prev_sibling && $prev_sibling->isa('PPI::Token::Comment')) {
        my $prev_prev_sibling = $prev_sibling->previous_sibling;
        $prev_sibling->delete;
        $prev_sibling = $prev_prev_sibling;
    }

    my $next_sibling = $use_stmt->next_sibling;

    while ($next_sibling && $next_sibling->isa('PPI::Token::Whitespace')) {
        my $next_next_sibling = $next_sibling->next_sibling;
        $next_sibling->delete;
        $next_sibling = $next_next_sibling;
    }

    $use_stmt->delete;
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
