use Test2::V0;
use Test2::Tools::Spec;
use Pau::Extract;

describe 'get_functions' => sub {
    it 'can extract functions' => sub {
        my $pau       = Pau::Extract->new('t/fixtures/Functions.pm');
        my $functions = $pau->get_functions;
        is $functions, array {
            item 'func_a';
            item 'func_b';
        };
    };
};

describe 'get_use_statements' => sub {
    it 'can extract use statements' => sub {
        my $pau            = Pau::Extract->new('t/fixtures/Uses.pm');
        my $use_statements = $pau->get_use_statements;
        is $use_statements, array {
            item hash {
                field 'type'           => 'use';
                field 'module'         => 'strict';
                field 'module_version' => '';
                field 'functions'      => [];
                field 'no_import'      => 0;
            };
            item hash {
                field 'type'           => 'use';
                field 'module'         => 'Animal';
                field 'module_version' => '';
                field 'functions'      => [ 'cat', 'dog' ];
                field 'no_import'      => 0;
            };
            item hash {
                field 'type'           => 'use';
                field 'module'         => 'Pen';
                field 'module_version' => '';
                field 'functions'      => [];
                field 'no_import'      => 1;
            };
            item hash {
                field 'type'           => 'no';
                field 'module'         => 'Trap';
                field 'module_version' => '';
                field 'functions'      => [];
                field 'no_import'      => 0;
            };
            item hash {
                field 'type'           => 'use';
                field 'module'         => 'Car';
                field 'module_version' => '1.10';
                field 'functions'      => [];
                field 'no_import'      => 0;
            };
            item hash {
                field 'type'           => 'require';
                field 'module'         => 'Japan::Kyoto';
                field 'module_version' => '';
                field 'functions'      => [];
                field 'no_import'      => 0;
            };
        }, 'can get use statements in order';
    };
};

done_testing;
