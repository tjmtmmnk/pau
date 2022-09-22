use Test2::V0;
use Test2::Tools::Spec;
use Pau::Finder;

describe 'find_exported_functions' => sub {
    it 'can find exported functions' => sub {
        my $functions =
          Pau::Finder->find_exported_function('t/fixtures/lib/ExportA.pm');
        is $functions, hash {
            field package => 'ExportA';
            field export  => array {
                item 'create_animal';
            };
            field export_ok => array {
                item 'create_human';
            };
        }, 'can find @EXPORT and @EXPORT_OK';
    };
    it 'can find multiple file' => sub {
        my $functions =
          Pau::Finder->find_exported_function('t/fixtures/lib/ExportA.pm');
        is $functions, hash {
            field package => 'ExportA';
            field export  => array {
                item 'create_animal';
            };
            field export_ok => array {
                item 'create_human';
            };
        };

        my $functions2 =
          Pau::Finder->find_exported_function('t/fixtures/lib/ExportB.pm');
        is $functions2, hash {
            field package => 'ExportB';
            field export  => array {
                item 'create_dog';
            };
            field export_ok => array {
                item 'create_cat';
            };
        };
    };
    it 'even if lib path end with /' => sub {
        local $ENV{PAU_LIB_PATH_LIST} = 't/fixtures/lib/';
        my $functions =
          Pau::Finder->find_exported_function('t/fixtures/lib/ExportA.pm');
        is $functions, hash {
            field export => array {
                item 'create_animal';
            };
            field export_ok => array {
                item 'create_human';
            };
        }, 'can find';
    };
};

done_testing;
