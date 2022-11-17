[![Actions Status](https://github.com/tjmtmmnk/pau/actions/workflows/ci.yml/badge.svg)](https://github.com/tjmtmmnk/pau/actions)
# NAME

Pau - It's new $module

# SYNOPSIS

    use Pau;

# DESCRIPTION

Pau is auto use tool.

## Usage
This example reads from stdin and print auto-used document to stdout.

    use Pau;
    my $source = "";

    while (<STDIN>) {
        $source .= $_;
    }
    my $formatted = Pau->auto_use($source);
    print(STDOUT $formatted);

## Environment Variables
`PAU_LIB_PATH_LIST`: default ''. Please set your using library, separated by spaces.
For example

    PAU_LIB_PATH_LIST='/cpan/lib/perl5 /app/your_project/lib'

`PAU_PAU_NO_CACHE`: default TRUE. If set to FALSE, create cache file for avoiding repeatedly loading exported functions.

`PAU_CACHE_DIR`: If you set PAU\_NO\_CACHE=TRUE, you must set this value. This value indicates under which directory the cache file should be created.

`PAU_DO_NOT_DELETE`: Pau delete unused include-statement automatically. This value prevents from incorrect deleting.

# LICENSE

Copyright (C) tjmtmmnk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tjmtmmnk <tjmtmmnk@gmail.com>
