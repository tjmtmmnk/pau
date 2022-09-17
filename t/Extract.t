use Test2::V0;
use Test2::Tools::Spec;
use Pau::Extract;

describe get_functions => sub {
    my $pau       = Pau::Extract->new('t/fixtures/Functions.pm');
    my $functions = $pau->get_functions;
    is $functions, array {
        item 'func_a';
        item 'func_b';
    };
};

done_testing;
