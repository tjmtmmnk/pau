use Test2::V0;
use Test2::Tools::Spec;
use Pau::Convert;

describe 'create_include_statement' => sub {
    it 'can create by raw use statement' => sub {
        my $stmt = Pau::Convert->create_include_statement('use Animal::Dog;');
        is $stmt, object {
            prop blessed => 'PPI::Statement::Include';
            call type   => 'use';
            call module => 'Animal::Dog';
        };
    };
    it 'can create by raw use statement with args' => sub {
        my $stmt =
            Pau::Convert->create_include_statement('use Animal::Dog qw(a b);');
        is $stmt, object {
            prop blessed => 'PPI::Statement::Include';
            call type   => 'use';
            call module => 'Animal::Dog';
        };
        my ($arg) = $stmt->arguments;
        my $literal = [ $arg->literal ];
        is $literal, array {
            item 'a';
            item 'b';
        }, 'can get args';
    };
    it 'die if invalid use statement' => sub {
        like dies {
            Pau::Convert->create_include_statement('my $a = 1;');
        }, qr/invalid use statement/;
    };
};

done_testing;
