package Decision::Table::Partial::Combinations;

    Class::Maker::class
    {
        isa => [qw( Decision::Table )],
    };

=head2 $dt->table

Returns a complete table of the condition status. The format is 

 $condition_id => action_result 

where the action result is often true || false.

 {
   '1' => false,
   '0' => true,
   '2' => true
 };

Note that you just need to reverse the hash to know if B<one> of the tests failed.

=cut

    sub table : method
    {
        my $this = shift;

	my @args = @_;
	
	my $result = {};
        
            foreach my $r ( $this->rules_as_objs )
            {
		    foreach my $cobj ( $r->conditions_as_objs( $this ) ) 
		    {      
		      Carp::croak "conditions must be Decision::Table::Condition::WithCode" unless $cobj->isa( 'Decision::Table::Condition::WithCode' );

		      $result->{ $cobj->text } = $cobj->execute( @args );		      
		    }                
            }        

    return $result;
    }

=head1 Decision::Table::Partial

This is a decision table that has an addtional attribute C<else>. If all conditions fail than this actions will be called.

 else => [ 0, 5, 2 ]

for example would call action 0, 5, and 2 if no conditions matched.

=cut

1;
