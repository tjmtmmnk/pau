package t::fixtures::UseFunctionG;

sub multiple {
    my $a = create_cat;
    my $b = create_cat();
    my $c = create_cat 1;
    my $c = create_cat(is_cat => 1);
}

1;

