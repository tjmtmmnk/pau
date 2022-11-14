# USAGE: cat [file] | docker compose run --rm -T app perl /app/script/ppi-dumper.pl
use lib qw(/app/cpan/lib/perl5 /app/lib);

use PPI::Document;
use PPI::Dumper;

my $source = "";

while (<STDIN>) {
    $source .= $_;
}

my $doc    = PPI::Document->new(\$source);
my $dumper = PPI::Dumper->new($doc);
$dumper->print;
