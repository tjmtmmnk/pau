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

        my $formatted      = Pau->auto_use($filename);
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

        my $formatted      = Pau->auto_use($filename);
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

        my $formatted      = Pau->auto_use($filename);
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

        my $formatted      = Pau->auto_use($filename);
        my $formatted_doc  = PPI::Document->new(\$formatted);
        my $formatted_incs = $formatted_doc->find('PPI::Statement::Include');
        is $formatted_incs, array {
            item object {
                call module => 'Creature::Human';
            };
            end;
        }, 'do not change';
    };
    it 'no use and no package' => sub {
        my $filename   = 't/fixtures/scriptA.pl';
        my $plain      = read_file($filename);
        my $plain_doc  = PPI::Document->new(\$plain);
        my $plain_incs = $plain_doc->find('PPI::Statement::Include');
        is $plain_incs, "", 'no use';

        my $formatted      = Pau->auto_use($filename);
        my $formatted_doc  = PPI::Document->new(\$formatted);
        use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };
        p $formatted;
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
};

done_testing;
