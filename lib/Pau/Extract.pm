package Pau::Extract;
use warnings;
use strict;
use List::Util qw(uniq);
use Try::Tiny;
use PPI::Document;
use PPI::Dumper;
use Pod::Functions '%Type';

use constant {
    INSTANCE_METHOD       => 1,
    CLASS_METHOD          => 2,
    BUILTIN_FUNCTIONS_MAP => {
        map { $_ => 1, } keys %Type,
        map { $_ => 1, } qw(if for while unless foreach),
    },
};

sub new {
    my ( $self, $filename ) = @_;
    my $doc   = PPI::Document->new($filename);
    my $subs  = $doc->find('PPI::Statement::Sub');
    my $incs  = $doc->find('PPI::Statement::Include');
    my $stmts = $doc->find(
        sub {
            # e.g) sleep 1;
            $_[1]->class eq 'PPI::Statement' ||

              # e.g) my $a = create_human;
              $_[1]->isa('PPI::Statement::Variable') ||

              # e.g) if(is_cat) {}
              $_[1]->isa('PPI::Statement::Compound');
        }
    );
    bless {
        doc   => $doc,
        stmts => $stmts ? $stmts : [],
        subs  => $subs  ? $subs  : [],
        incs  => $incs  ? $incs  : [],
    }, $self;
}

# return: [Str]
sub get_declared_functions {
    my $self = shift;
    my $subs = $self->{subs};
    return [ map { $_->name } @$subs ];
}

# return: PPI::Statement::Include | PPI::Statement::Package
sub get_insert_point {
    my $self     = shift;
    my $includes = $self->{incs};
    return $includes->[-1] if scalar(@$includes) > 0;

    return $self->doc->find_first('PPI::Statement::Package');
}

# return: [{ type => Str, module => Str, functions => [Str], no_import => Bool, version => Str }]
sub get_use_statements {
    my $self     = shift;
    my $includes = $self->{incs};

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

    my $is_contain_package = $word_token->content =~ /([A-Z]\w+(::)?)+/;
    return undef unless $is_contain_package;

    # e.g) A::B->new
    my $is_instance_method = $word_token->snext_sibling->content eq '->'
      && ( $word_token->snext_sibling->snext_sibling
        && $word_token->snext_sibling->snext_sibling->isa('PPI::Token::Word') );

    return INSTANCE_METHOD if $is_instance_method;

    # e.g) A::B::new
    my $is_class_method = ( $word_token->content =~ /^(\w+::)+\w+$/ )
      && $word_token->snext_sibling->isa('PPI::Structure::List');

    return CLASS_METHOD if $is_class_method;

    return undef;
}

# return: [Str]
sub get_function_packages {
    my $self = shift;

    my $packages = [];
    for my $stmt ( $self->{stmts}->@* ) {
        my $words = $stmt->find('PPI::Token::Word');
        next unless $words;
        for my $word (@$words) {
            my $method_type = $self->_method_type($word);
            next unless defined $method_type;

            if ( $method_type == INSTANCE_METHOD ) {
                push @$packages, $word->content;
            }
            elsif ( $method_type == CLASS_METHOD ) {
                if ( $word->content =~ /^((\w+::)+)\w+$/ ) {
                    push @$packages, substr( $1, 0, -2 );
                }
            }
        }
    }
    return $packages;
}

# return: [Str]
sub get_functions {
    my $self = shift;

    my $functions = [];
    for my $stmt ( $self->{stmts}->@* ) {
        my $words = $stmt->find('PPI::Token::Word');
        next unless $words;
        for my $word (@$words) {
            my $is_method_call = try {
                return $word->method_call;
            }
            catch {
                return 0;
            };
            unless ($is_method_call) {
                my $is_package = $word->content =~ /::/;
                my $is_builtin = BUILTIN_FUNCTIONS_MAP->{ $word->content };
                if ( !$is_package && !$is_builtin ) {
                    push @$functions, $word->content;
                }
            }
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
