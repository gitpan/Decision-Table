package Decision::Table::Rule::Serial;

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

    for ( Data::Iter::iter scalar $this->true )
    {
	my $c = $dt->conditions->[ $_->COUNTER ];

	$c->id = $_->COUNTER;

	$c->expected = $_->VALUE;

	push @result, $c;
    }

return @result;
}

sub true_false_compare
{
    my $this = shift;

    my $dimension = shift;

    warn "ODD = ", Data::Dump::dump @_ unless scalar @_ % 2 == 0;

    my $args = {@_};


    my $result = [0,0];

    if( exists $args->{true} )
    {
	if( scalar @{ $args->{true} } > 0)
	{
	    my $a = Class::Maker::Types::Array->new( array => $args->{true} || [] );
	    
	    my $b = Class::Maker::Types::Array->new( array => [ $this->true ] );
	    	    
	    my $c = Class::Maker::Types::Array->new( array => [ $this->rule_indices_to_bool_array( $dimension, $this->true ) ] );

	    $result->[0] = $a->eq( $b ) ? 1 : 0;

#	    if( $DEBUG )
#	    if( $result->[0] )
	    {
		lnf STDERR "\t\tSerial/SUCCESS: TRUE_FALSE_COMPARE TRUE: args=%-10s rule=%-10s rule_bool=%-10s MATCH=%s", $a->join( ', ' ), $b->join( ', ' ), $c->join(', '), $result->[0] ? 'YES' : 'no';
		

	    }
	}
    }

    if( exists $args->{false} )
    {
	if( scalar @{ $args->{false} } > 0)
	{
	    my $a = Class::Maker::Types::Array->new( array => $args->{false} || [] );
	    
	    my $b = Class::Maker::Types::Array->new( array => [ $this->false ] );
	    
	    $result->[1] = $a->eq( $b ) ? 1 : 0;
	    
	    if( $result->[1] )
	    {
#		if( $DEBUG )
		{
		    lnf STDERR "\t\tSerial/SUCCESS: TRUE_FALSE_COMPARE FALSE: args=%-10s rule=%-10s rule_bool=%-10s", $a->join( ', ' ), $b->join( ', ' ), $c->join(', ');
		}
	    }
	}	
    }

#    ln STDERR "true_false_compare result: ", Data::Dump::dump( $result );

return $result;
}

1;

__END__

=head1 Decision::Table::Rule::Serial

=cut
