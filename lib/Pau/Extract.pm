package Pau::Extract;

use warnings;
use strict;
use PPI;

sub new {
    my ( $self, $filename ) = @_;
    my $doc = PPI::Document->new($filename);
    bless { doc => $doc, }, $self;
}

sub get_functions {
    my ($self) = @_;
    my $vars = $self->{doc}->find('PPI::Statement::Sub');
    return [ map { $_->name } @$vars ];
}

1;
