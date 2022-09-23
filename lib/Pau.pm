package Pau;
use Pau::Extract;
use Pau::Convert;
use Pau::Finder;
use PPI::Token::Whitespace;
use Array::Diff;
use JSON::XS;
use File::Slurp qw(read_file);
use Try::Tiny;

use List::Util qw(first);

use constant {
    CACHE_FILE_FUNCTIONS  => '/app/.cache/functions.json',
    CACHE_FILE_FOR_SEARCH => '/app/.cache/for_search.json',
};

# auto add and delete package
sub auto_use {
    my ( $class, $filename ) = @_;

    my $extractor = Pau::Extract->new($filename);

    my $current_use_statements = $extractor->get_use_statements;
    my $current_packages = [ map { $_->{module} } @$current_use_statements ];
    my $need_packages    = $extractor->get_function_packages;
    my $added_packages =
      Array::Diff->diff( $current_packages, $need_packages )->added;

    my $stmts = [ map { Pau::Convert->create_include_statement("use $_;") }
          @$added_packages ];

    my $need_package_to_functions = {};
    my $functions                 = $extractor->get_functions;
    my $cached_functions = $class->_read_json_file(CACHE_FILE_FUNCTIONS);
    if ($cached_functions) {
        my $func_to_package = $class->_func_to_package($cached_functions);
        for my $func (@$functions) {
            if ( my $pkg = $func_to_package->{$func} ) {
                $need_package_to_functions->{$pkg} //= [];
                push $need_package_to_functions->{$pkg}->@*, $func;
            }
        }
    }
    else {
        my $lib_files = Pau::Finder->get_lib_files;

        my $functions = [];
        for my $lib_file (@$lib_files) {
            my $exported_function =
              Pau::Finder->find_exported_function($lib_file);
            push @$functions, $exported_function;
        }
        $class->_create_json_file( CACHE_FILE_FUNCTIONS, $functions );

        my $func_to_package = $class->_func_to_package($cached_functions);
        $class->_create_json_file( CACHE_FILE_FOR_SEARCH, $func_to_package );
    }

    for my $pkg ( keys %$need_package_to_functions ) {
        my $functions = join( ' ', $need_package_to_functions->{$pkg}->@* );
        push @$stmts,
          Pau::Convert->create_include_statement("use $pkg qw($functions);");
    }

    my $insert_point = $extractor->get_insert_point;
    $insert_point->add_element( PPI::Token::Whitespace->new("\n") );

    for my $s (@$stmts) {
        $s->add_element( PPI::Token::Whitespace->new("\n") );
        $insert_point->insert_after($s);
    }

    use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };
    p $extractor->{doc}->serialize;
}

# make search more efficient by creating HashRef with key: function
# from ArrayRef[{ package => Str, functions => ArrayRef[Str] }], to HashRef[function => package]
sub _func_to_package {
    my ( $class, $functions ) = @_;
    return {
        map {
            my $package = $_->{package};
            my $funcs   = $_->{functions};
            map { $_ => $package, } @$funcs,
        } @$functions
    };
}

sub _read_json_file {
    my ( $class, $filename ) = @_;
    my $data = try {
        read_file($filename)
    }
    catch {
        undef;
    };
    return $data ? decode_json($data) : undef;
}

sub _create_json_file {
    my ( $class, $filename, $data ) = @_;
    open my $fh, '>', $filename or die qq/Can't open file "$filename" : $!/;
    print $fh encode_json($data);
    close $fh or die qq/Can't close file $filename: $!/;
}

1;
