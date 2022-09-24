use Test2::V0;
use Test2::Tools::Spec;
use Pau;
use File::Slurp qw(read_file);

describe 'auto_use' => sub {
    describe 'exist pragma use' => sub {
        my $filename   = 't/fixtures/UseFunctionA.pm';
        my $plain      = read_file($filename);
        my $plain_doc  = PPI::Document->new( \$plain );
        my $plain_incs = $plain_doc->find('PPI::Statement::Include');
        is $plain_incs, array {
            item object {
                call module => 'warnings';
            };
            item object {
                call module => 'strict';
            };
        }, 'can get only pragma';

        my $formatted      = Pau->auto_use('t/fixtures/UseFunctionA.pm');
        my $formatted_doc  = PPI::Document->new( \$formatted );
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
                call module => 'Vehicle::Car';
            };
        }, 'can get sorted needed package, and not deleted pragma';
    };
};

done_testing;
