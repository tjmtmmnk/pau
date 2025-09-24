requires 'PPI',                   '1.274';
requires 'Try::Tiny',             '0.31';
requires 'JSON::XS',              '4.03';
requires 'File::Slurp',           '9999.32';
requires 'Module::CoreList',      '5.20220920';
requires 'Data::Printer',         '1.000004';
requires 'List::Util',            '1.59';
requires 'Smart::Args::TypeTiny', '0.13';
requires 'Data::UUID',            '1.226';
requires 'Symbol::Get',           '0.10';
requires 'Parallel::ForkManager', '2.02';
requires 'List::MoreUtils',       '0.430';

on 'test' => sub {
    requires 'Test2',        '1.302191';
    requires 'Test2::Suite', '0.000145';
    requires 'Test::More',   '0.98';
};
