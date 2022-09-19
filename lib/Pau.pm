package Pau;
use Pau::Extract;
use Pau::Convert;
use PPI::Token::Whitespace;

sub insert_use_statements {
    my ( $class, $filename ) = @_;

    my $extractor = Pau::Extract->new($filename);

    my $current_use_statements = $extractor->get_use_statements;
    my $current_packages = [ map { $_->{module} } @$current_use_statements ];
    my $need_packages    = $extractor->get_function_packages;
    my $stmts = [ map { Pau::Convert->create_include_statement("use $_;") }
          @$need_packages ];

    my $insert_point = $extractor->get_insert_point;
    $insert_point->add_element( PPI::Token::Whitespace->new("\n") );

    for my $s (@$stmts) {
        $s->add_element( PPI::Token::Whitespace->new("\n") );
        $insert_point->insert_after($s);
    }

    use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };
    p $extractor->{doc}->serialize;
}

1;
