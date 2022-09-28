requires 'PPI',         '== 1.274';
requires 'Try::Tiny',   '== 0.31';
requires 'List::Util',  '== 1.59';
requires 'JSON::XS',    '== 4.03';
requires 'File::Slurp', '== 9999.32';
requires 'Class::Load', '== 0.25';

on 'develop' => sub {
    requires 'Data::Printer', '== 1.000004';
};

on 'test' => sub {
    requires 'Test2',        '== 1.302191';
    requires 'Test2::Suite', '== 0.000145';
};
