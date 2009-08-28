package Decision::Table::Partial;

use strict;
use warnings;

our $DEBUG = 1;

    Class::Maker::class
    {
        isa => [qw( Decision::Table )],
    };

=head2 $dt->run

return rule results as 

  [[1, 0, 1], [1, 1], [1, 0], [0, 1]]

and the rules obj private member '_true_false_results' fields are set to the results as well:

  [
    bless({ _true_false_results => [1, 0, 1], actions => [2, 1], true => [0, 1, 2] }, "Decision::Table::Rule::Indexed"),
    bless({ _true_false_results => [1, 1], actions => [1], true => [0, 2] }, "Decision::Table::Rule::Indexed"),
    bless({ _true_false_results => [1, 0], actions => [0], true => [0, 1] }, "Decision::Table::Rule::Indexed"),
    bless({ _true_false_results => [0, 1], actions => [0], true => [1, 2] }, "Decision::Table::Rule::Indexed"),
  ],

=cut

    sub run : method
    {
        my $this = shift;

	my @args = @_;
	
	my $result = [];

        my $rules_found_true=0;

            foreach my $r ( Data::Iter::iter [ $this->rules_as_objs ] )
            {
		my $verdict = [];

		    foreach my $cobj ( Data::Iter::iter [ $r->VALUE->conditions_as_objs( $this ) ] ) 
		    {      
		      Carp::croak "conditions must be Decision::Table::Condition::WithCode" unless $cobj->VALUE->isa( 'Decision::Table::Condition::WithCode' );

		      my $v = $cobj->VALUE->execute( @args );

		      $r->VALUE->_true_false_results->[$cobj->COUNTER] = $v;

		      push @$verdict, $v;
		    }                

		if( $r->VALUE->results_last_all_true )
		    {
			IO::Extended::println "EXECUTING CODE " if $DEBUG;

			foreach $_ ( Data::Iter::iter [ $r->VALUE->actions_as_objs( $this ) ] ) 
			{   
			    IO::Extended::indn if $DEBUG;

			    IO::Extended::printfln "ACTION #%d = %S", $r->VALUE->actions->[ $_->COUNTER ], $_->VALUE->text if $DEBUG;

			    if( $_->VALUE->isa( 'Decision::Table::Action::WithCode' ) )
			    {
				IO::Extended::indn if $DEBUG;

				IO::Extended::println " ACTION BEFORE: args= ", Data::Dump::dump \@args if $DEBUG;

				$_->VALUE->cref->( @args );

				IO::Extended::println " ACTION AFTER: args= ", Data::Dump::dump \@args if $DEBUG;
			    }
			}
			$rules_found_true++;
		    }

		push @$result, $verdict;
            }        

	IO::Extended::println "CHECKING FOR ELSE: rules_found_true", $rules_found_true if $DEBUG;

	unless( $rules_found_true )
	{
	    IO::Extended::println ref($this), " ELSE ACTIONS EXECUTING" if $DEBUG;

	    for( @{ $this->else } )
	    {
		$_ = $this->actions->[ $_ ];
		
		if( $_->isa( 'Decision::Table::Action::WithCode' ) )
		{
		    IO::Extended::indn if $DEBUG;
		    
		    IO::Extended::println " ACTION BEFORE: args= ", Data::Dump::dump \@args if $DEBUG;
		    
		    $_->cref->( @args );
		    
		    IO::Extended::println " ACTION AFTER: args= ", Data::Dump::dump \@args if $DEBUG;
		}
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
