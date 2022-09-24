package t::fixtures::UseFunctionA;
use warnings;
use strict;

sub wan {
    my $dog = create_animal('dog');
    $dog->wan;
}

sub nyan {
    if(is_cat) {
        warn 'nyaaaan';
    }
    no_func;
}

sub piyo {
    my $a = create_cat;
}

sub uoo {
    my $human = Creature::Human->new('worker');
    Creature::Human->new;
    Vehicle::Car::new();
}

sub zoom {
    my $car = Vehicle::Car::new();
    $car->run;
}

