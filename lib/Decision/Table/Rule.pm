package Decision::Table::Rule;

use IO::Extended qw(:all);

use Data::Dump qw(dump);

our $DEBUG = 0;

	Class::Maker::class
	{
		public =>
		{
		    array => [qw( true false true_false_results actions )],

		    scalar => [qw( id )],
		},

		private =>
		{
		    array => [qw( true_false_results )],
		},
	};

=head1 Decision::Table::Rule

=cut

sub actions_as_objs : method
{
    my $this = shift;

    my $dt = shift || Carp::croak;


return map { $dt->actions->[ $_ ] } @{ $this->actions };
}




sub results_last_all_true : method
{
    my $this = shift;

    my $cnt;

    for( $this->_true_false_results )
    {
	$cnt++ if $_;
    }

    if( defined $cnt && @{ $this->_true_false_results } )
    {
	return 1 if $cnt == @{ $this->_true_false_results };
    }

return 0;
}

sub rule_indices_to_bool_array : method
{
    my $this = shift;

    my $dimension = shift;

    my @result = map { 0 } 1.. $dimension;

    for( @_ )
    {
	$result[$_] = 1;
    }

return @result;
}

=head1 Decision::Table::Rule::Indexed

=cut

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

	    $result->[0] = $a->eq( $c ) ? 1 : 0;

	    if( $DEBUG )
#	    if( $result->[0] )
	    {
		lnf STDERR "\t\tRule/SUCCESS: TRUE_FALSE_COMPARE TRUE: args=%-10s rule=%-10s rule_bool=%-10s SUCESS=%s", $a->join( ', ' ), $b->join( ', ' ), $c->join(', '), $result->[0] ? 'OK' : 'fail';
		

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
	    
#	    if( $result->[1] )
	    {
		if( $DEBUG )
		{
		    lnf STDERR "\t\tRule/SUCCESS: TRUE_FALSE_COMPARE FALSE: args=%-10s rule=%-10s rule_bool=%-10s", $a->join( ', ' ), $b->join( ', ' ), $c->join(', ');
		}
	    }
	}	
    }

#    ln STDERR "true_false_compare result: ", Data::Dump::dump( $result );

return $result;
}

1;

__END__

=head1 Rules and Boolean algebra

Rules are mathematically treatable with  boolean algebra. As Decision::Table's can represent almost any logic, it is often interesting to understand what it encodes. For example if you see it as a neural network, you can train/cross/manipulate/optimize it. Because i partly translated the following texts from german books i preseved the original quotes within [DE ...].

Following basic arithmetics seems to be important in this context. 

 - are two rules the same (=)      [DE ob die Regeln gleich sind (=)]
 - rule greater than another (>)   [DE ob eine Regel größer ist als die andere (>)]
 - rule less than another (<)      [DE ob eine Regel kleiner ist als die andere (<)]
 - do two rules cross (x)          [DE ob sich die beiden Regeln überkreuzen (x)]
                                   [DE ob die beiden Regeln sich gegenseitig ausschließen (x)]

=head2 Axiom: redundance [DE überflüssige Regeln]

One or two rules are redundant if both rules are in their action part identical.

[DE Ein von zwei Regeln ist überflüssig, wenn die beiden Regeln im Aktionsteil identisch sind.]

=head2 Axiom: contradiction [DE Widerspruch]

An error exists if two B<identical> rules have contradictionary action parts.

[DE Ein Fehler liegt vor, wenn zwei gleiche Regeln entgegengesetzte Aktionen enthalten.]

=head2 Axiom: inclusion [DE Eine Regeln enthält die andere]

Rule1 includes rule2, if rule 1 always gets assigned when rule 2 is assigned.

[DE Die Regel 1 enthält die Regel 2, wenn die Regel 1 immer dann zutrifft, wenn auch die Regel 2 zutrifft.]

=head2 Axiom: crossing [DE Zwei Regeln überkreuzen sich]

Rule1 and rule2 cross, if rule1 and rule2 can be assigned simultaneously.

[DE Die Regel 1 und 2 überkreuzen sich, wenn Regel 1 und Regel 2 gleichzeitig eintreten können.]

=head1 OPTIMIZATION 

=head2 The "OR"-scenario

Multiple conditions lead to the same action-combination. These conditions may be optimized as follows:

[DE Mehrer Bedinungen münden in die gleiche Decision::Table::Actions-kombination. Diese Bedingungen können wie folgt abgekürzt werden:]

Original

	if( ... )
	{
		...
	}
	elsif( A and B )
	{
		Decision::Table::ActionA
	}
	elsif( C and D )
	{
		Decision::Table::ActionA
	}

is verbose from of

	if( (A and B) OR (C and D) )
	{
		Decision::Table::ActionA
	}

[DE MUENALAN: Eigentlich gilt ja "Ein von zwei Regeln ist überflüssig, wenn diebeiden Regeln im Aktionsteil identisch sind.".
Ob dieses wirklich stimmt ?]

=head2 List of actions with identical actions [DE Aktionenslisten mit identischen Aktionen]

Two list of actions partially overlap by some actions.

[DE Falls zwei Aktionenslisten identische Aktionen enhalten, können für diese optimierte "if"-verschachtelungen
aufgebaut werden:]

Example:

	rules =>
	{
		[ 1, 0, 1 ] => [ 0 ],
		[ 1, 1, 1 ] => [ 0, 1 ],
	}

The original

		if( [ 1, 0, 1 ] )
		{
			[ 0 ]
		}
		elsif( [ 1, 1, 1 ] )
		{
			[ 0, 1 ]
		}

is optimizable to

		if( [ 1, X, 1 ] )
		{
			[ 0 ]

			if( [ X, 1, X ] )
			{
				[ 1 ],
			}
		}

Note: Decision::Table::Action [0] B<BEFORE> of second "if". Otherwise the logic is not equivalent.

[DE MUENALAN Diese gilt aber (glaube ich) nur wenn sie in der gleichen Reihenfolge stehen].

Example

	rules =>
	{
		[ 1, 0, 1 ] => [ 0 ],
		[ 1, 1, 1 ] => [ 1, 0 ],
	}

is optimizable to

	if( [ 1, X, 1 ] )
	{
		if( [ X, 1, X ] )
		{
			[ 1 ],
		}

		[ 0 ]
	}

Note: Decision::Table::Action [0] !AFTER! the second C<if>. Otherwise the logic is not equivalent.

=head1 Author

Murat Ueanlan <muenalan@cpan.org>

