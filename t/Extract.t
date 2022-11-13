use Test2::V0;
use Test2::Tools::Spec;
use Pau::Extract;
use File::Slurp qw(read_file);

describe 'get_declared_functions' => sub {
    it 'can extract functions' => sub {
        my $filename  = 't/fixtures/Functions.pm';
        my $plain     = read_file($filename);
        my $pau       = Pau::Extract->new($plain);
        my $functions = $pau->get_declared_functions;
        is $functions, array {
            item 'func_a';
            item 'func_b';
        };
    };
};

describe 'get_use_statements' => sub {
    it 'can extract use statements' => sub {
        my $filename       = 't/fixtures/Uses.pm';
        my $plain          = read_file($filename);
        my $pau            = Pau::Extract->new($plain);
        my $use_statements = $pau->get_use_statements;
        is $use_statements, array {
            item hash {
                field 'stmt'           => D;
                field 'type'           => 'use';
                field 'module'         => 'Animal';
                field 'module_version' => '';
                field 'functions'      => [ 'cat', 'dog' ];
                field 'arg_list'       => U;
                field 'using'          => 0;
            };
            item hash {
                field 'stmt'           => D;
                field 'type'           => 'use';
                field 'module'         => 'Pen';
                field 'module_version' => '';
                field 'functions'      => [];
                field 'arg_list'       => D;
                field 'using'          => 0;
            };
            item hash {
                field 'stmt'           => D;
                field 'type'           => 'no';
                field 'module'         => 'Trap';
                field 'module_version' => '';
                field 'functions'      => [];
                field 'arg_list'       => U;
                field 'using'          => 0;
            };
            item hash {
                field 'stmt'           => D;
                field 'type'           => 'use';
                field 'module'         => 'Car';
                field 'module_version' => '1.10';
                field 'functions'      => [];
                field 'arg_list'       => U;
                field 'using'          => 0;
            };
            item hash {
                field 'stmt'           => D;
                field 'type'           => 'require';
                field 'module'         => 'Japan::Kyoto';
                field 'module_version' => '';
                field 'functions'      => [];
                field 'arg_list'       => U;
                field 'using'          => 0;
            };
        }, 'no pragma';
    };
};

describe 'get_function_packages' => sub {
    it 'can get instance and class method packages' => sub {
        my $filename = 't/fixtures/UseFunctionA.pm';
        my $plain    = read_file($filename);
        my $pau      = Pau::Extract->new($plain);
        my $packages = $pau->get_function_packages;
        is $packages, array {
            item 'Creature::Human';
            item 'Vehicle::Car';
        };
    };
    it 'can get one character package' => sub {
        my $filename = 't/fixtures/UseFunctionE.pm';
        my $plain    = read_file($filename);
        my $pau      = Pau::Extract->new($plain);
        my $packages = $pau->get_function_packages;
        is $packages, array {
            item 'C';
        };
    };
};

describe 'get_functions' => sub {
    it 'can get function names' => sub {
        my $filename  = 't/fixtures/UseFunctionA.pm';
        my $plain     = read_file($filename);
        my $pau       = Pau::Extract->new($plain);
        my $functions = $pau->get_functions;
        is $functions, array {
            item 'create_animal';
            item 'create_cat';
        }, 'can get uniquely';
    };
    it 'can get function names in various uses' => sub {
        my $filename  = 't/fixtures/UseFunctionC.pm';
        my $plain     = read_file($filename);
        my $pau       = Pau::Extract->new($plain);
        my $functions = $pau->get_functions;
        is $functions, array {
            item 'create_animal';
            item 'is_cat';
            item 'no_func';
            item 'create_cat';
        }, 'can get also not exported func';
    };
    it 'can ignore same name but not function' => sub {
        my $filename  = 't/fixtures/UseFunctionF.pm';
        my $plain     = read_file($filename);
        my $pau       = Pau::Extract->new($plain);
        my $functions = $pau->get_functions;
        is $functions, array { end; };
    };
};

describe 'get_insert_point' => sub {
    it 'exist use statements' => sub {
        my $filename     = 't/fixtures/UseFunctionA.pm';
        my $plain        = read_file($filename);
        my $pau          = Pau::Extract->new($plain);
        my $insert_point = $pau->get_insert_point;
        is $insert_point, object {
            prop blessed => 'PPI::Statement::Include';
            call module => 'strict';
        }, 'can get last use statement';
    };
    it 'no use statements, exist package' => sub {
        my $filename     = 't/fixtures/UseFunctionB.pm';
        my $plain        = read_file($filename);
        my $pau          = Pau::Extract->new($plain);
        my $insert_point = $pau->get_insert_point;
        is $insert_point, object {
            prop blessed => 'PPI::Statement::Package';
            call namespace => 't::fixtures::UseFunctionB';
        }, 'can get last use statement';
    };
    it 'no use statements, no package' => sub {
        my $filename     = 't/fixtures/scriptA.pl';
        my $plain        = read_file($filename);
        my $pau          = Pau::Extract->new($plain);
        my $insert_point = $pau->get_insert_point;
        is $insert_point, U;
    };
};

done_testing;
