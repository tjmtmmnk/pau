package t::fixtures::UseFunctionA;
use warnings;
use strict;

sub wan {
    my $dog = create_animal('dog');
    $dog->wan;
}

sub nyan {
    create_cat->sing;
}

sub uoo {
    my $human = Creature::Human->new('worker');
    $human->shout;
}

sub zoom {
    my $car = Vehicle::Car::new();
    $car->run;
}

