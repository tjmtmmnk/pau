package t::fixtures::UseFunctionF;

sub uoo {
    my $a = {
        create_cat => 1,
    };
    my $b =~ /create_cat/;
    my $c = {};
    $c->{create_cat} = 1;
    my %d = (create_cat => 1);
    my $e = $d{create_cat};
}

