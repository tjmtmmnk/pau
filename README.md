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
    my $formatted = Pau->auto_use(
        source    => $source,
        lib_paths => ['lib', 't/lib', 'cpan/lib/perl5'],
    );
    print(STDOUT $formatted);

# DESCRIPTION

Pau inserts use-statement if not exist, and deletes use-statement if not used.

# LICENSE

Copyright (C) tjmtmmnk.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tjmtmmnk <tjmtmmnk@gmail.com>
