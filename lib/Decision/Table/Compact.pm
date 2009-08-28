package Decision::Table::Compact;


our $DEBUG = 1;

use Decision::Table::Condition;
    
use Decision::Table::Action;

    Class::Maker::class
    {
        isa => [qw( Decision::Table )],
    };

=head1 Decision::Table::Compact

This table is a Decision::Table with a different constructor. It takes scalars instead of objects. C<Decision::Table::Condition> are constructed with the C<text> attribute filled with the scalar. Same as the actions initialized with c<Decision::Table::Action> objects.

  my $dt = Decision::Table::Compact->new( 
    
      conditions =>
      [
       'drove too fast ?',
       'comsumed alcohol ?',
       'Police is making controls ?',
      ],
      
      actions =>
      [
       'charged admonishment',         # 0
       'drivers license cancellation', # 1
       'nothing happened',             # 2
      ],
      
      # @conditions => @actions
      
      rules =>
      [
      [ 1, 0, 1 ] => [ 0 ],
      [ 1, 1, 1 ] => [ 0, 1 ],
      [ 0, 0, 0 ] => [ 2 ],
      ],
 );

Note: $dt->conditions property (and actions) will handle $objects as normal. Only the constructor is different.

=cut

sub _arginit : method
{
    my $this = shift;

    my $orig_args = shift;

    my %args = @$orig_args;


    my $class_condition = 'Decision::Table::Condition';
    
    my $class_action = 'Decision::Table::Action';

    for( @{ $args{conditions} } )
    {
	$_ = $class_condition->new( text => $_ );
    }

    for( @{ $args{actions} } )
    {
	$_ = $class_action->new( text => $_ );
    }


    warn "ARGINIT CALLED, dump = ", Data::Dump::dump [%args] if $DEBUG;

return $orig_args = [%args];
}


=head2 $dt->table

Returns a complete table of the condition status. The format is 

 $condition_id => action_result 

where the action result is often true || false.

 {
   '0' => true,
   '1' => false,
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

1;
