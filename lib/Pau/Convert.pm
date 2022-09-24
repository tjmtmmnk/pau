package Pau::Convert;
use warnings;
use strict;
use PPI::Document;

sub _make_document_by_string {
    my ($class, $str) = @_;
    return PPI::Document->new(\"$str");
}

# convert to PPI::Statement::Include
sub create_include_statement {
    my ($class, $raw_include_statement) = @_;
    my $doc               = $class->_make_document_by_string($raw_include_statement);
    my $include_statement = $doc->find_first('PPI::Statement::Include');
    die "invalid use statement" unless $include_statement;

    return $include_statement->clone;
}

1;
