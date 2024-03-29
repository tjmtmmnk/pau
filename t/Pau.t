use Test2::V0;
use Test2::Tools::Spec;
use Pau;
use File::Slurp qw(read_file);

describe 'auto_use' => sub {
    it 'exist pragma use' => sub {
        my $filename   = 't/fixtures/UseFunctionA.pm';
        my $plain      = read_file($filename);
        my $plain_doc  = PPI::Document->new(\$plain);
        my $plain_incs = $plain_doc->find('PPI::Statement::Include');
        is $plain_incs, array {
            item object {
                call module => 'warnings';
            };
            item object {
                call module => 'strict';
            };
            end;
        }, 'can get only pragma';

        my $formatted = Pau->auto_use(
            source    => $plain,
            lib_paths => ['t/fixtures/lib'],
            use_cache => !!0,
        );
        my $formatted_doc  = PPI::Document->new(\$formatted);
        my $formatted_incs = $formatted_doc->find('PPI::Statement::Include');
        is $formatted_incs, array {
            item object {
                call module => 'warnings';
            };
            item object {
                call module => 'strict';
            };
            item object {
                call module => 'Creature::Human';
            };
            item object {
                call module    => 'ExportA';
                call arguments => 1;
            };
            item object {
                call module    => 'ExportB';
                call arguments => 1;
            };
            item object {
                call module => 'Vehicle::Car';
            };
            end;
        }, 'can get sorted needed package, and not deleted pragma';
    };
    it 'no use' => sub {
        my $filename   = 't/fixtures/UseFunctionB.pm';
        my $plain      = read_file($filename);
        my $plain_doc  = PPI::Document->new(\$plain);
        my $plain_incs = $plain_doc->find('PPI::Statement::Include');
        is $plain_incs, "", 'no use';

        my $formatted = Pau->auto_use(
            source    => $plain,
            lib_paths => ['t/fixtures/lib'],
            use_cache => !!0,
        );
        my $formatted_doc  = PPI::Document->new(\$formatted);
        my $formatted_incs = $formatted_doc->find('PPI::Statement::Include');
        is $formatted_incs, array {
            item object {
                call module    => 'ExportB';
                call arguments => 1;
            };
            end;
        }, 'can get needed package';
    };
    it 'various functions' => sub {
        my $filename   = 't/fixtures/UseFunctionC.pm';
        my $plain      = read_file($filename);
        my $plain_doc  = PPI::Document->new(\$plain);
        my $plain_incs = $plain_doc->find('PPI::Statement::Include');
        is $plain_incs, array {
            item object {
                call module => 'warnings';
            };
            item object {
                call module => 'strict';
            };
        }, 'can get only pragma';

        my $formatted = Pau->auto_use(
            source    => $plain,
            lib_paths => ['t/fixtures/lib'],
            use_cache => !!0,
        );
        my $formatted_doc  = PPI::Document->new(\$formatted);
        my $formatted_incs = $formatted_doc->find('PPI::Statement::Include');
        is $formatted_incs, array {
            item object {
                call module => 'warnings';
            };
            item object {
                call module => 'strict';
            };
            item object {
                call module => 'Creature::Human';
            };
            item object {
                call module    => 'ExportA';
                call arguments => 1;
            };
            item object {
                call module    => 'ExportB';
                call arguments => 1;
            };
            item object {
                call module => 'Vehicle::Car';
            };
            end;
        }, 'can get sorted needed package, and not deleted pragma';

        my ($arg_ExportA) = $formatted_incs->[3]->arguments;
        my $literalA = [ $arg_ExportA->literal ];
        is $literalA, array {
            item 'create_animal';
            end;
        }, 'can get arguments';

        my ($arg_ExportB) = $formatted_incs->[4]->arguments;
        my $literalB = [ $arg_ExportB->literal ];
        is $literalB, array {
            item 'create_cat';
            item 'is_cat';
            end;
        }, 'can get sorted arguments';
    };
    it 'already used' => sub {
        my $filename   = 't/fixtures/UseFunctionD.pm';
        my $plain      = read_file($filename);
        my $plain_doc  = PPI::Document->new(\$plain);
        my $plain_incs = $plain_doc->find('PPI::Statement::Include');
        is $plain_incs, array {
            item object {
                call module => 'Creature::Human';
            };
            end;
        }, 'used';

        my $formatted = Pau->auto_use(
            source    => $plain,
            lib_paths => ['t/fixtures/lib'],
            use_cache => !!0,
        );
        my $formatted_doc  = PPI::Document->new(\$formatted);
        my $formatted_incs = $formatted_doc->find('PPI::Statement::Include');
        is $formatted_incs, array {
            item object {
                call module => 'Creature::Human';
            };
            end;
        }, 'do not change';
    };
    it 'called function multiple times' => sub {
        my $filename   = 't/fixtures/UseFunctionG.pm';
        my $plain      = read_file($filename);
        my $plain_doc  = PPI::Document->new(\$plain);
        my $plain_incs = $plain_doc->find('PPI::Statement::Include');
        is $plain_incs, "", 'no use';

        my $formatted = Pau->auto_use(
            source    => $plain,
            lib_paths => ['t/fixtures/lib'],
            use_cache => !!0,
        );
        my $formatted_doc  = PPI::Document->new(\$formatted);
        my $formatted_incs = $formatted_doc->find('PPI::Statement::Include');
        is $formatted_incs, array {
            item object {
                call module => 'ExportB';
            };
            end;
        };
        my ($arg_ExportB) = $formatted_incs->[0]->arguments;
        my $literalB = [ $arg_ExportB->literal ];
        is $literalB, array {
            item 'create_cat';
            end;
        }, 'can get one argument';
    };
    it 'no use and no package' => sub {
        my $filename   = 't/fixtures/scriptA.pl';
        my $plain      = read_file($filename);
        my $plain_doc  = PPI::Document->new(\$plain);
        my $plain_incs = $plain_doc->find('PPI::Statement::Include');
        is $plain_incs, "", 'no use';

        my $formatted = Pau->auto_use(
            source    => $plain,
            lib_paths => ['t/fixtures/lib'],
            use_cache => !!0,
        );
        my $formatted_doc  = PPI::Document->new(\$formatted);
        my $formatted_incs = $formatted_doc->find('PPI::Statement::Include');
        is $formatted_incs, array {
            item object {
                call module => 'ExportA';
            };
            item object {
                call module => 'ExportB';
            };
            end;
        }, 'can get sorted needed package';
    };
    it 'can parse use statement with args' => sub {
        my $filename   = 't/fixtures/UseFunctionH.pm';
        my $plain      = read_file($filename);
        my $plain_doc  = PPI::Document->new(\$plain);
        my $plain_incs = $plain_doc->find('PPI::Statement::Include');
        is $plain_incs, array {
            item object {
                call module => 'Creature::Human';
            };
            item object {
                call module    => 'ExportB';
                call arguments => 1;
            };
            item object {
                call module => 'Accessor';
            };
            item object {
                call module => 'Deleted';
            };
            end;
        };
        my ($arg_ExportB) = $plain_incs->[1]->arguments;
        my $literalB = [ $arg_ExportB->literal ];
        is $literalB, array {
            item 'create_cat';
            end;
        };

        my $formatted = Pau->auto_use(
            source    => $plain,
            lib_paths => ['t/fixtures/lib'],
            use_cache => !!0,
        );
        my $formatted_doc  = PPI::Document->new(\$formatted);
        my $formatted_incs = $formatted_doc->find('PPI::Statement::Include');
        is $formatted_incs, array {
            item object {
                call module => 'Creature::Human';
            };
            item object {
                call module    => 'ExportB';
                call arguments => 1;
            };
            end;
        };
        my ($arg_ExportB2) = $formatted_incs->[1]->arguments;
        my $literalB2 = [ $arg_ExportB2->literal ];
        is $literalB2, array {
            item 'create_cat';
            item 'is_cat';
            end;
        }, 'added is_cat';
    };
    it 'can remain if do_not_delete_modules is specified' => sub {
        my $filename  = 't/fixtures/UseFunctionH.pm';
        my $plain     = read_file($filename);
        my $formatted = Pau->auto_use(
            source                => $plain,
            lib_paths             => ['t/fixtures/lib'],
            do_not_delete_modules => ['Accessor'],
            use_cache             => !!0,
        );
        my $formatted_doc  = PPI::Document->new(\$formatted);
        my $formatted_incs = $formatted_doc->find('PPI::Statement::Include');
        is $formatted_incs, array {
            item object {
                call module => 'Creature::Human';
            };
            item object {
                call module => 'Accessor';
            };
            item object {
                call module    => 'ExportB';
                call arguments => 1;
            };
            end;
        };
    };
};

done_testing;
