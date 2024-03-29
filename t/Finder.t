use Test2::V0;
use Test2::Tools::Spec;
use Pau::Finder;

describe 'get_lib_files' => sub {
    it 'can find nested files' => sub {
        my $files = Pau::Finder->get_lib_files(lib_paths => ['t/fixtures/lib']);
        is $files, bag {
            item 't/fixtures/lib/C.pm';
            item 't/fixtures/lib/ExportA.pm';
            item 't/fixtures/lib/ExportB.pm';
            item 't/fixtures/lib/ExportC.pm';
            item 't/fixtures/lib/ExportD.pm';
            item 't/fixtures/lib/One/First.pm';
            item 't/fixtures/lib/One/Two/Second.pm';
            end;
        };
    };
};

describe 'find_core_module_exported_functions' => sub {
    it 'can find core module List::Util' => sub {
        my $pkg_to_core_functions = Pau::Finder->find_core_module_exported_functions;
        is $pkg_to_core_functions->{'List::Util'}, bag {
            item 'max';
            item 'first';
            etc;
        }, 'can get exported functions';
    };
};

describe 'find_exported_functions' => sub {
    unshift @INC, 't/fixtures/lib';    # unshifted in Pau.pm, so this is just only for test purpose

    it 'can find exported functions' => sub {
        my $functions = Pau::Finder->find_exported_function(
            filename  => 't/fixtures/lib/ExportA.pm',
            lib_paths => ['t/fixtures/lib'],
        );
        is $functions, hash {
            field package   => 'ExportA';
            field functions => array {
                item 'create_animal';
                item 'create_human';
            };
        }, 'can find @EXPORT and @EXPORT_OK';
    };
    it 'can find multiple file' => sub {
        my $functions = Pau::Finder->find_exported_function(
            filename  => 't/fixtures/lib/ExportA.pm',
            lib_paths => ['t/fixtures/lib'],
        );
        is $functions, hash {
            field package   => 'ExportA';
            field functions => array {
                item 'create_animal';
                item 'create_human';
                end;
            };
        };

        my $functions2 = Pau::Finder->find_exported_function(
            filename  => 't/fixtures/lib/ExportB.pm',
            lib_paths => ['t/fixtures/lib'],
        );
        is $functions2, hash {
            field package   => 'ExportB';
            field functions => array {
                item 'create_dog';
                item 'create_cat';
                item 'is_cat';
                item 'create_flog';
                end;
            };
        };
    };
    it 'even if lib path end with /' => sub {
        my $functions = Pau::Finder->find_exported_function(
            filename  => 't/fixtures/lib/ExportA.pm',
            lib_paths => ['t/fixtures/lib/'],
        );
        is $functions, hash {
            field package   => 'ExportA';
            field functions => array {
                item 'create_animal';
                item 'create_human';
                end;
            };
        }, 'can find';
    };
};

done_testing;
