package Pau::Extract;
use warnings;
use strict;
use List::Util qw(uniq);
use PPI::Document;
use PPI::Dumper;

use constant {
    INSTANCE_METHOD => 0,
    CLASS_METHOD    => 1,
    METHOD          => 2,
};

use Class::Accessor::Lite::Lazy (
    ro      => [qw(doc)],
    ro_lazy => [qw(words subs includes)],
);

sub new {
    my ( $self, $filename ) = @_;
    my $doc = PPI::Document->new($filename);
    bless { doc => $doc, }, $self;
}

sub _build_words {
    my $self  = shift;
    my $words = $self->doc->find('PPI::Token::Word');
    return $words ? $words : [];
}

sub _build_subs {
    my $self = shift;
    my $subs = $self->doc->find('PPI::Statement::Sub');
    return $subs ? $subs : [];
}

sub _build_includes {
    my $self = shift;
    my $incs = $self->doc->find('PPI::Statement::Include');
    return $incs ? $incs : [];
}

# return: [Str]
sub get_declared_functions {
    my $self = shift;
    my $subs = $self->subs;
    return [ map { $_->name } @$subs ];
}

# return: PPI::Statement::Include | PPI::Statement::Package
sub get_insert_point {
    my $self     = shift;
    my $includes = $self->includes;
    return $includes->[-1] if scalar(@$includes) > 0;

    return $self->doc->find_first('PPI::Statement::Package');
}

# return: [{ type => Str, module => Str, functions => [Str], no_import => Bool, version => Str }]
sub get_use_statements {
    my $self     = shift;
    my $includes = $self->includes;

    my $use_statements = [];
    for my $inc (@$includes) {
        next if $inc->pragma;
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

sub _method_type {
    my ( $self, $word_token ) = @_;

    return undef unless $word_token && $word_token->snext_sibling;

    # e.g) A::B->new
    my $is_instance_method = $word_token->snext_sibling->content eq '->'
      && ( $word_token->snext_sibling->snext_sibling
        && $word_token->snext_sibling->snext_sibling->isa('PPI::Token::Word') );

    return INSTANCE_METHOD if $is_instance_method;

    # e.g) A::B::new
    my $is_class_method = ( $word_token->content =~ /^(\w+::)+\w+$/ )
      && $word_token->snext_sibling->isa('PPI::Structure::List');

    return CLASS_METHOD if $is_class_method;

    # e.g) create_animal
    my $is_method = $word_token->snext_sibling->isa('PPI::Structure::List');

    return METHOD if $is_method;

    return undef;
}

# return: { packages: [Str] }
sub get_function_packages {
    my $self     = shift;
    my $words    = $self->words;
    my $packages = [];
    for my $word (@$words) {
        my $type = $self->_method_type($word);

        next unless defined $type;

        if ( $type == INSTANCE_METHOD ) {
            push @$packages, $word->content;
        }
        elsif ( $type == CLASS_METHOD ) {
            if ( $word->content =~ /^((\w+::)+)\w+$/ ) {
                push @$packages, substr( $1, 0, -2 );
            }
        }
    }
    return [ uniq @$packages ];
}

# return: [Str]
sub get_functions {
    my $self      = shift;
    my $words     = $self->words;
    my $functions = [];
    for my $word (@$words) {
        my $type = $self->_method_type($word);

        next unless defined $type;

        if ( $type == METHOD ) {

            # avoid matching instance method
            my $is_instance_method =
                 $word->sprevious_sibling
              && $word->sprevious_sibling->isa('PPI::Token::Operator')
              && $word->sprevious_sibling->content eq '->';
            next if $is_instance_method;

            push @$functions, $word->content;
        }
    }
    return [ uniq @$functions ];
}

sub dump {
    my $self   = shift;
    my $dumper = PPI::Dumper->new( $self->doc );
    $dumper->print;
}

1;
