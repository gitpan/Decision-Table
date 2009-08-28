package Decision::Table::Weighted;

use 5.006; use strict; use warnings;

our $DEBUG = 0;

use IO::Extended qw(:all);

use Decision::Table::Diagnostic;

Class::Maker::class
{
	isa => [qw( Decision::Table::Diagnostic )],
	
	public => 
	{
		array => [qw( weights )],
	},
};
        
    sub decide 
    {
        my $this = shift;
        
        my $weights = { };
        
                # step through the conditions and calc the cumulative weight
                
            for my $r ( @{ $this->rules } )
            {
		my $cnt=0;

                foreach my $c ( $this->lookup( 'conditions', @{ $r->true } ) )
                {
                    print "C: ", $c->text, " [", $c->weight, "]\n" if $DEBUG;
                    
                    my $r = $c->execute( @_ ) if $c->isa( 'Decision::Table::Condition::WithCode' );
                    
                    $weights->{ $cnt++ } += $c->weight if defined $r;
                }
                
                print "\n" if $DEBUG;
            }        

	IO::Extended::println Data::Dump::dump $weights;

                # goto height weight and execute the actions
                            
            my $result = reverse_hash_grouped( $weights );

	IO::Extended::println Data::Dump::dump $result;

            my ($best) = ( sort { $b <=> $a } keys %$result );

	IO::Extended::println "Best is: ", Data::Dump::dump $result->{$best};
            
            foreach my $i ( @{ $result->{$best} } )
            {                        
                my $r = $this->rules->[$i];

                for my $a ( $this->lookup( 'actions', @{$r->actions} ) )
                {                    
                    print "\t $i) ", $a->text, "\n" if $DEBUG;
                    
                    $a->execute( @_ ) if $a->isa( 'Decision::Table::Action::WithCode' );
                }
            }
                    
    return $result;
    }
    
    # a helper
    
sub reverse_hash_grouped
{
	my $href = shift or die;

	use Data::Iter qw(:all);

	my %unique = reverse %$href;
	
	my $result = {};

	foreach my $w ( sort { $b <=> $a } keys %unique )
	{	
		#print $w, "\n";
		
		foreach ( iter $href )
		{
			#print join( ', ', key, value, counter ), "\n";
			
			if( defined key )
			{
				if( value == $w )
				{                        
					$result->{$w} = [] unless exists $result->{$w};
					
					push @{ $result->{$w} }, key, 
				}
			}
		}
	}

return $result;
}

package Decision::Table::Condition::Weighted;

	Class::Maker::class
	{
	    isa => [qw( Decision::Table::Condition::WithCode )],
	    
		public =>
		{
			scalar => [qw( weight )],
			
			ref => [qw( context )],
		},
	};

1;

__END__

=head1 NAME

Decision::Table::Weighted - decisions are made by weighted criteria

=head1 SYNOPSIS

  use Decision::Table;

    my $wheather_context = Context->new( text => 'Summer' );
    
    my $dtp;
    
	##
	## Weighted Decision::Table::Conditions for Categorizing Decision Tables
	##
	##    highest weight (i.e. 0-100 => 100) means evidentiary 
	#
	## This exampe shows "Localization (Where am i in the universum?)"
    
    $Decision::Table::Weighted::DEBUG = 1;

    $dtp = Decision::Table::Weighted->new(
	
    conditions =>
    [
    Decision::Table::Condition::Weighted->new( text => 'Inhabitats are small', weight => 30, cref => sub { $_[0]->size eq 'small' } ),
    Decision::Table::Condition::Weighted->new( text => 'Inhabitats are large', weight => 30, cref => sub { $_[0]->size eq 'large' } ),
    Decision::Table::Condition::Weighted->new( text => 'Inhabitats have dark skin', weight => 90, cref => sub { $_[0]->skin eq 'dark' } ),
    Decision::Table::Condition::Weighted->new( text => 'Whether is hot', weight => 10, cref => sub { $_[1]->temperature eq 'hot' } ),
    Decision::Table::Condition::Weighted->new( text => 'It is rainy', weight => 10, cref => sub { $_[1]->humidity eq 'rainy' } ),
    Decision::Table::Condition::Weighted->new( text => 'I have seen a kangoroo', weight => 99, cref => sub { exists $_[1]->animals->{'kangoroo'} } ),
    Decision::Table::Condition::Weighted->new( text => 'I have seen a desert', weight => 80, cref => sub { $_[1]->landscape eq '' } ),
    ],
    
    actions =>
    [
    Decision::Table::Action->new( id => 'eu', text => 'Europe' ),
    Decision::Table::Action->new( id => 'as', text => 'Asia' ),
    Decision::Table::Action->new( id => 'am', text => 'Amerika' ),
    Decision::Table::Action->new( id => 'au', text => 'Australia' ),
    Decision::Table::Action->new( id => 'af', text => 'Afrika' ),
    ],
    
    rules =>
    [
    [ 0, 1, 2 ] => [ 1 ],
    [ 1, 2 ]    => [ 2 ],
    [ 0, 2, 5 ] => [ 3 ],
    [ 0, 3 ]    => [ 4 ],
    ],
    
    else => [ 3 ],
    );

    class 'Inhabitant',
    {
      public =>
      {
	string => [qw( size skin )],
      },
    };

    class 'Enviroment',
    {
      public =>
      {
         string => [qw( humidity temperature landscape )],

         hash => [qw( animals )],
      },
    };

    my $i = Inhabitant->new( size => 'small', skin => 'dark' );

    my $e = Enviroment->new( humidity => 'rainy', temperature => 'cold', animals => { kangoroo => 1 }, landscape => 'desert' );
	
    print Dumper [ $dtp->decide( $i, $e ) ];

=head1 DESCRIPTION

This decision table is similar to ::Diagnostic decision tables, but not same. Here you give the (false or true) conditions a
weight and then count it to decide. This is very similar to how my brain makes decisions (without exactly counting number, but
accumulating a "feeling" about it). Interesting is that some weights are so high that they are absolutely pointing into one direction.
In medical terms it is called "pathognomonic" (as in the synopsis the kangoroo is very tied to Australia). But this is just one
facet of this decision table type.

=head1 METHODS

=head2 $dt = Decision::Table::Diagnostic->new( conditions => [], actions => [], rules => [], else => [ ] )

=over 5

=item -
conditions
the condition objects in an aref

=item -
actions
action objects in an aref

=item -
rules
a condition action combinatorial hash (see L<Decision::Table> constructor).

=item -
else
the action (index) called when no rule applied (attests that this is a B<partial> decision table)

=back

=head2 $dt->decide( $object, [ ... ] )

Computes the weights. The conditions (Decision::Table::Condition::WithCode) coderef get the C<$object>'s as arguments to calculate the weights. The result
is a highscore table as

 {
    $weighted => [ $action_id, $action_id,  ... ],
 }

=head1 Decision::Table::Condition::Weighted

=head2 $dt = Decision::Table::Condition::Weighted->new( weight => $scalar, context => $context  )

=over 5

=item -
weight
a numerical value added to the comulative weight if $cref returns true.

=item -
cref
coderef to a subroutine that get C<$object>'s and $context as arguments (see C<$dt-E<gt>decide>).

=item -
context
an object that helps to make the decision

=back

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Ünalan, E<lt>muenalan@cpan.orgE<gt>

=head1 SEE ALSO

L<Decision::Table>, L<Decision::Table::Diagnostic>

=head1 REFERENCES

<1> Book (German): M. Rammè, "Entscheidungstabellen: Entscheiden mit System" (Prentice Hall))
