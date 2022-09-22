use Test2::V0;
use Test2::Tools::Spec;
use Pau::Finder;

describe 'find_exported_functions' => sub {
    it 'can find exported functions' => sub {
        my $functions =
          Pau::Finder->find_exported_functions('t/lib/ExportA.pm');
        is $functions, array {
            item 'create_animal';
        }, 'can get exported functions only in @EXPORT';
    };
};

done_testing;
