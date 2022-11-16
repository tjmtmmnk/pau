#!/usr/bin/env perl
# USAGE: docker run --rm -e PAU_LIB_PATH_LIST='lib' -it -v cache-vol:/app/.cache -v (pwd):/src pau:1.0 A.pm

BEGIN {
    # assure end of path is not /
    # e.g) lib (not lib/)
    @lib_path_list = map {
        (my $path = $_) =~ s/\/$//;
        $path;
    } split(/ /, $ENV{PAU_LIB_PATH_LIST});
}

use lib qw(/app/cpan/lib/perl5 /app/lib);
use lib @lib_path_list;

use Pau;

my $source = "";

while (<STDIN>) {
    $source .= $_;
}
my $formatted = Pau->auto_use($source);
print(STDOUT $formatted);
