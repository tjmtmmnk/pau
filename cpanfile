requires 'PPI',             '== 1.274';
requires 'Try::Tiny',       '== 0.31';
requires 'List::Util',      '== 1.59';

on 'develop' => sub {
    requires 'Data::Printer', '== 1.000004';
};

on 'test' => sub {
    requires 'Test2',        '== 1.302191';
    requires 'Test2::Suite', '== 0.000145';
};
