[![Actions Status](https://github.com/tjmtmmnk/pau/actions/workflows/ci.yml/badge.svg)](https://github.com/tjmtmmnk/pau/actions)
# NAME

Pau - Perl Auto Use module

# SYNOPSIS
This example reads from stdin and print auto-used document to stdout.

    use Pau;
    my $source = "";

    while (<STDIN>) {
        $source .= $_;
    }
    my $formatted = Pau->auto_use($source);
    print(STDOUT $formatted);

# DESCRIPTION

Pau inserts use-statement if not exist, and deletes use-statement if not used.

## Environment Variables

> &#x3d;item\* `PAU_LIB_PATH_LIST`
>
> default: `''`.
> Please set your using library, separated by spaces.
>
> For example,
>
>     PAU_LIB_PATH_LIST='/cpan/lib/perl5 /app/your_project/lib'
>
> &#x3d;item\* `PAU_NO_CACHE`
>
> default: `TRUE`.
> If set to FALSE, create cache file for avoiding repeatedly loading exported functions.
>
> &#x3d;item\* `PAU_CACHE_DIR`
>
> If you set PAU\_NO\_CACHE=TRUE, you must set this value.
> This value indicates under which directory the cache file should be created.
>
> &#x3d;item\* `PAU_DO_NOT_DELETE`
>
> default: `''`.
> Pau delete unused include-statement automatically. This value prevents from incorrect deleting.

# LICENSE

Copyright (C) tjmtmmnk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tjmtmmnk <tjmtmmnk@gmail.com>
