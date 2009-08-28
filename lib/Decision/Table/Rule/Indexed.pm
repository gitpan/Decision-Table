package Decision::Table::Rule::Indexed;

use IO::Extended qw(:all);

use Data::Dump qw(dump);

	Class::Maker::class
	{
	    isa => [qw(Decision::Table::Rule)],
	};

sub conditions_as_objs : method
{
    my $this = shift;

    my $dt = shift || Carp::croak;

    
    my @result;

    foreach ( @{ $this->true } )
    {
	my $c = $dt->conditions->[ $_ ];

	$c->id = $_;

	$c->expected = 1;
	
	push @result, $c;
    }

return @result;
}

sub rule_indices_to_bool_array : method
{
    my $this = shift;


    my @result = map { 0 } @_;

    for( @_ )
    {
	$result[$_] = 1;
    }

return @result;
}

1;

__END__
