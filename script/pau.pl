#!/usr/bin/env perl
use Pau;
use lib '/app/lib';
use lib '/cpan/lib/perl5';

# USAGE: docker run --rm -e PAU_LIB_PATH_LIST='lib' -it -v cache-vol:/app/.cache -v (pwd):/src pau:1.0 A.pm

my $filename  = shift;
my $formatted = Pau->auto_use($filename);
print $formatted;
