package Pau;
use strict;
use warnings;
use utf8;

our $VERSION = "0.091";

use Pau::Extract;
use Pau::Convert;
use Pau::Util;
use Pau::Finder;
use PPI::Token::Whitespace;
use List::Util qw(uniq);
use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };
use Carp qw(croak);
use Module::CoreList;
use Smart::Args::TypeTiny qw(args);
use Parallel::ForkManager;
use List::MoreUtils qw(natatime);

use List::Util qw(first);

# auto add and delete package
sub auto_use {
    args my $class                => 'ClassName',
        my $lib_paths             => 'ArrayRef[Str]',
        my $source                => 'Str',
        my $use_cache             => { isa => 'Bool',          default  => !!0 },
        my $cache_dir             => { isa => 'Str',           optional => 1 },
        my $jobs                  => { isa => 'Int',           optional => 1 },
        my $debug                 => { isa => 'Bool',          default  => !!0 },
        my $do_not_delete_modules => { isa => 'ArrayRef[Str]', optional => 1 },
        ;

    if (!defined $jobs) {
        my $uname = `uname`;
        chomp($uname);
        $jobs = $uname eq 'Linux' ? `nproc` : `sysctl -n hw.physicalcpu`;
        chomp($jobs);
    }

    for (@$lib_paths) {
        unshift @INC, $_;
    }

    my $should_set_cache_dir = $use_cache && !defined $cache_dir;
    croak 'Please set cache_dir. example cache_dir=/var/tmp' if $should_set_cache_dir;

    my $extractor = Pau::Extract->new($source);

    my $current_use_statements        = $extractor->get_use_statements;
    my $current_pkg_to_use_statements = { map {
            $_->{module} => $_
    } @$current_use_statements };

    my $need_package_to_functions = {};

    my $need_packages = $extractor->get_function_packages;

    if ($debug) {
        p "need packages";
        p $need_packages;
    }

    for my $pkg (@$need_packages) {
        my $already_used = defined $need_package_to_functions->{$pkg} && scalar $need_package_to_functions->{$pkg}->@* > 0;

        unless ($already_used) {
            $need_package_to_functions->{$pkg} = [];
        }
    }

    my $used_functions = $extractor->get_functions;

    if ($debug) {
        p "used functions";
        p $used_functions;
    }

    my $lib_files = Pau::Finder->get_lib_files(lib_paths => $lib_paths);

    if ($debug) {
        p "lib files";
        p $lib_files;
    }

    my $pkg_to_functions = $class->_collect(
        lib_files => $lib_files,
        lib_paths => $lib_paths,
        cache_dir => $cache_dir,
        jobs      => $jobs,
    );

    my $func_to_pkgs = {
        map {
            my $pkg   = $_;
            my $funcs = $pkg_to_functions->{$pkg};
            map {
                $_ => $pkg,
            } @$funcs,
        } keys %$pkg_to_functions,
    };

    if ($debug) {
        p "func to pkgs";
        p $func_to_pkgs;
    }

    for my $func (@$used_functions) {
        if (my $pkg = $func_to_pkgs->{$func}) {
            $need_package_to_functions->{$pkg} //= [];
            push $need_package_to_functions->{$pkg}->@*, $func;
        }
    }

    if ($debug) {
        p "need pkg to funcs";
        p $need_package_to_functions;
    }

    my $statements = [];

    # sort desc to be inserted asc
    my $sorted_need_packages =
        [ sort { lc($b) cmp lc($a) } keys %$need_package_to_functions ];

    my $should_create_include_stmt = sub {
        my ($current_use_stmt, $need_functions) = @_;

        if (defined $current_use_stmt) {
            if (my $current_use_functions = $current_use_stmt->{functions}) {
                my $all_contain = 1;

                for my $need_function (@$need_functions) {
                    my $is_contain = grep { $_ eq $need_function } @$current_use_functions;

                    unless ($is_contain > 0) {
                        $all_contain = 0;
                        last;
                    }
                }
                return !$all_contain;
            }
            else {
                return 0;
            }
        } else {
            return 1;
        }
    };

    for my $pkg (@$sorted_need_packages) {
        if ($should_create_include_stmt->($current_pkg_to_use_statements->{$pkg}, $need_package_to_functions->{$pkg})) {
            my $functions =
                join(' ', sort { lc($a) cmp lc($b) } uniq $need_package_to_functions->{$pkg}->@*);
            my $stmt =
                $functions eq ''
                ? "use $pkg;"
                : "use $pkg qw($functions);";
            push @$statements, Pau::Convert->create_include_statement($stmt);
        } else {
            $current_pkg_to_use_statements->{$pkg}->{using} = 1;
        }
    }

    my $unused_current_use_stmts = [ grep { !$_->{using} } @$current_use_statements ];

    for my $unused_use_stmt (@$unused_current_use_stmts) {
        my $do_not_delete = grep { $_ eq $unused_use_stmt->{module} } @$do_not_delete_modules;

        unless ($do_not_delete) {
            $class->_delete_use_statement($unused_use_stmt->{stmt});
        }
    }

    if ($debug) {
        p "statements";
        p $statements;
    }

    $class->_insert_statements($extractor, $statements);

    return $extractor->{doc}->serialize;
}

# returns: HashRef[pkg => functions]
sub _collect {
    args my $class    => 'ClassName',
        my $lib_files => 'ArrayRef[Str]',
        my $lib_paths => 'ArrayRef[Str]',
        my $cache_dir => 'Maybe[Str]',
        my $jobs      => 'Int',
        ;

    my $collect_from_files = sub {
        my $files            = shift;
        my $pkg_to_functions = {};
        my $pm               = Parallel::ForkManager->new($jobs);
        $pm->run_on_finish(
            sub {
                my ($pid, $exit_code, $ident, $exit_signal, $core_dump, $funcs) = @_;

                if (defined($funcs)) {
                    for my $func (@$funcs) {
                        $pkg_to_functions->{ $func->{package} } = $func->{functions};
                    }
                }
            }
        );

        my $itr = natatime 1000, @$files;

        while (my @bulk_files = $itr->()) {
            $pm->start and next;
            my $funcs = [ map {
                    Pau::Finder->find_exported_function(
                        filename  => $_,
                        lib_paths => $lib_paths,
                    )
            } @bulk_files ];

            $pm->finish(0, $funcs);
        }
        $pm->wait_all_children;

        return $pkg_to_functions;
    };

    my $do_not_cache = !defined $cache_dir;

    if ($do_not_cache) {
        return +{
            Pau::Finder->find_core_module_exported_functions->%*,
            $collect_from_files->($lib_files)->%*,
        };
    } else {
        my $functions_cache_file      = File::Spec->catfile($cache_dir, 'pau-functions.json');
        my $core_functions_cache_file = File::Spec->catfile($cache_dir, 'pau-core-functions.json');

        my $pkg_to_functions      = Pau::Util->read_json_file($functions_cache_file)      // {};
        my $core_pkg_to_functions = Pau::Util->read_json_file($core_functions_cache_file) // Pau::Finder->find_core_module_exported_functions;

        $pkg_to_functions = {
            %$pkg_to_functions,
            %$core_pkg_to_functions,
        };

        my $last_cached_at = Pau::Util->last_modified_at($functions_cache_file);

        my $stale_lib_files = [ grep {
                my $last_modified_at = Pau::Util->last_modified_at($_);
                $last_modified_at > $last_cached_at;
        } @$lib_files ];

        $pkg_to_functions = {
            %$pkg_to_functions,
            $collect_from_files->($stale_lib_files)->%*,
        };

        my $should_save_pkg_to_functions      = scalar(@$stale_lib_files) > 0;
        my $should_save_core_pkg_to_functions = Pau::Util->last_modified_at($core_pkg_to_functions) == 0;
        Pau::Util->write_json_file($functions_cache_file,      $pkg_to_functions)      if $should_save_pkg_to_functions;
        Pau::Util->write_json_file($core_functions_cache_file, $core_pkg_to_functions) if $should_save_core_pkg_to_functions;

        return $pkg_to_functions;
    }
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
__END__

=encoding utf-8

=head1 NAME

Pau - Perl Auto Use module

=head1 SYNOPSIS
This example reads from stdin and print auto-used document to stdout.

    use Pau;
    my $source = "";

    while (<STDIN>) {
        $source .= $_;
    }
    my $formatted = Pau->auto_use(
        source    => $source,
        lib_paths => ['lib', 't/lib', 'cpan/lib/perl5'],
    );
    print(STDOUT $formatted);

=head1 DESCRIPTION

Pau inserts use-statement if not exist, and deletes use-statement if not used.

=head1 LICENSE

Copyright (C) tjmtmmnk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tjmtmmnk E<lt>tjmtmmnk@gmail.comE<gt>

=cut
