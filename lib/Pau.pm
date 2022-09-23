package Pau;
use Pau::Extract;
use Pau::Convert;
use Pau::Finder;
use PPI::Token::Whitespace;
use Array::Diff;

use List::Util qw(first);

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

    my $functions     = $extractor->get_functions;
    my $lib_path_list = [
        map {
            ( my $path = $_ ) =~ s/\/$//;
            $path;
        } split( / /, $ENV{PAU_LIB_PATH_LIST} )
    ];
    my $lib_files =
      [ glob join( ' ', map { $_ . '/*' } @$lib_path_list ) ];
    for my $lib_file (@$lib_files) {
        my $exported_function = Pau::Finder->find_exported_function($lib_file);
        for my $function (@$functions) {
            for my $export_function ( $exported_function->{export}->@* ) {
                my $exist_in_export = $function eq $export_function;
                if ($exist_in_export) {
                    push @$stmts,
                      Pau::Convert->create_include_statement(
                        "use @{[ $exported_function->{package} ]}};");
                }
            }
            for my $export_ok_function ( $exported_function->{export_ok}->@* ) {
                my $exist_in_export_ok = $function eq $export_ok_function;
                if ($exist_in_export_ok) {
                    push @$stmts,
                      Pau::Convert->create_include_statement(
"use @{[ $exported_function->{package} ]} qw(@{[ $function ]})};"
                      );
                }
            }
        }
    }

    my $insert_point = $extractor->get_insert_point;
    $insert_point->add_element( PPI::Token::Whitespace->new("\n") );

    for my $s (@$stmts) {
        $s->add_element( PPI::Token::Whitespace->new("\n") );
        $insert_point->insert_after($s);
sub _read_cache {
    my $class = shift;
    my $file  = CACHE_FILE;
    my $data  = try {
        read_file($file)
    }
    catch {
        undef;
    };
    return $data ? decode_json($data) : undef;
}

sub _create_cache {
    my ( $class, $data ) = @_;
    my $file = CACHE_FILE;
    open my $fh, '>', $file or die qq/Can't open file "$file" : $!/;
    print $fh encode_json($data);
    close $fh or die qw/Can't close file "$file": $!/;
}

1;
