package Pau::Extract;

use warnings;
use strict;
use PPI::Document;
use PPI::Dumper;

sub new {
    my ( $self, $filename ) = @_;
    my $doc = PPI::Document->new($filename);
    bless { doc => $doc, }, $self;
}

# return: [Str]
sub get_functions {
    my $self = shift;
    my $subs = $self->{doc}->find('PPI::Statement::Sub');
    return [ map { $_->name } @$subs ];
}

# return: [{ type => Str, module => Str, functions => [Str], no_import => Bool, version => Str }]
sub get_use_statements {
    my $self     = shift;
    my $includes = $self->{doc}->find('PPI::Statement::Include');

    my $use_statements = [];
    for my $inc (@$includes) {
        my $statement = {
            type           => $inc->type,
            module         => $inc->module,
            module_version => $inc->module_version
            ? $inc->module_version->content
            : "",
            functions => [],
            no_import => 0,
        };

        my ($arg) = $inc->arguments;
        if ($arg) {
            if ( $arg->isa('PPI::Token::QuoteLike::Words') ) {
                $statement->{functions} = [ $arg->literal ];
            }
            elsif ( $arg->isa('PPI::Structure::List') ) {
                if ( $arg->content eq '()' ) {
                    $statement->{no_import} = 1;
                }
            }
        }
        push @$use_statements, $statement;
    }
    return $use_statements;
}

sub dump {
    my $self   = shift;
    my $dumper = PPI::Dumper->new( $self->{doc} );
    $dumper->print;
}

1;
