requires 'PPI',              '== 1.274';
requires 'Try::Tiny',        '== 0.31';
requires 'JSON::XS',         '== 4.03';
requires 'File::Slurp',      '== 9999.32';
requires 'Module::CoreList', '== 5.20220920';
requires 'Data::Printer',    '== 1.000004';

on 'test' => sub {
    requires 'Test2',        '== 1.302191';
    requires 'Test2::Suite', '== 0.000145';
};
