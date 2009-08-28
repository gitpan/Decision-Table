package Decision::Table::Complete;

    Class::Maker::class
    {
        isa => [qw( Decision::Table )],
    };

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

1;

__END__

=head1 Decision::Table::Complete

If this decision table is used there B<must> be on condition/action pair that gets executed, otherwise the decision fails. This is very helpfull where precise handling of all eventualies is expected. So you can be sure that you handle all constellations of conditions with an appropriate action. The contra point is that you may need extreme big tables when you have many conditions (n^n).

=cut


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
