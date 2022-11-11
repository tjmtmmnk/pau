# USAGE: cat [file] | docker compose run --rm -T app perl /app/script/ppi-dumper.pl
use lib '/app/cpan/lib/perl5';

use PPI::Document;
use PPI::Dumper;

my $source = "";

while (<STDIN>) {
    $source .= $_;
}

my $doc    = PPI::Document->new(\$source);
my $dumper = PPI::Dumper->new($doc);
$dumper->print;

my $stmts = $doc->find(
    sub {
        # e.g) sleep 1;
        $_[1]->class eq 'PPI::Statement';
    }
);
use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };
my $incs = $doc->find(sub { $_[1]->isa('PPI::Statement::Include') });
use DDP { show_unicode => 1, use_prototypes => 0, colored => 1 };
p $incs;

for my $s (@$stmts) {
    for my $i (@$incs) {
        if ($s->descendant_of($i)) {
            warn "aaaaaaaaaa";
        }
    }
}
