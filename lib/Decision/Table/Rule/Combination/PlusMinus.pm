package Decision::Table::Rule::Combination::PlusMinus;

use strict;
use warnings;

our $DEBUG = 0;

	Class::Maker::class
	{
	    isa => [qw(Decision::Table::Rule)],

	    public =>
	    {
		array => [qw(translated)],

		scalar => [qw(code)],
	    }

	};

sub _postinit : method
{
    my $this = shift;

    $this->translated( digest( $this->code ) );
}

sub conditions_as_objs : method
{
    my $this = shift;

    my $dt = shift || Carp::croak;


    my @result;

    for ( Data::Iter::iter scalar $dt->conditions )
    {
	my $c = $dt->conditions->[ $_->counter ];

	$c->id = $_->counter;

	$c->expected = $_->value;

	push @result, $c;
    }

return @result;
}


sub score
{
	my $string = shift;
		
		my $val;
		
		$val += 
		  ( 
		   { 
		    '+' => 1, 
		    '-' => -1 
		   }->{$_} || 0 
		  ) 
		    foreach split //, $string; 
	
return $val;
}

sub digest
{
	my $encoded = shift || die;
	
	my $counter = 0;

return [ map { $_ } map { score( $_ ) } ( $encoded =~ m/(...)\s?/g ) ];
}

	# returns the distance of two values, even they are mixed plus/minus

sub _func_distance
{
	my $dest = shift;
	
	my $start = shift;
		
		# shift both values above the minus level, so we could simply subtract a - b 
	
	if( $dest > $start )
	{
		if( $start < 0 )
		{
			return ( $dest + ($start*-1) ) - ( $start + ($start*-1) );
		}

		return $dest - $start;
	}
	elsif( $dest < $start ) 
	{
		if( $dest < 0 )
		{
			return ( $start + ($dest*-1) ) - ( $dest + ($dest*-1) );
		}
		
		return $start - $dest;
	}
	
return 0;   
}

=head2 Decision::Table::Diagnostic::distance( $a, $b );

Helps the above functions. It calculates a distance (d) between two rules.

=cut

sub func_distance
{
	my $one = shift;
	
	my $two = shift;
	
	my @result;
	
	for( my $i=0; $i < @$one; $i++ ) 
	{
		push @result, _func_distance( $one->[$i], $two->[$i] );
	}

return \@result;
}

sub distance : method
{
    my $this = shift;

    my $string = shift;


    my $translated_from_string = digest( $string );
    
    my $result = func_distance( $translated_from_string, scalar $this->translated );

    IO::Extended::println "->distance(): a,b,result ", 

    Data::Dump::dump $translated_from_string, scalar $this->translated, $result if $DEBUG;

    return $result;

}

sub distance_sum : method
{
    my $this = shift;

    my $string = shift;

return _sumarray( @{$this->distance( $string )} );
}

sub _sumarray
{
	my $sum;
	
	$sum += $_ foreach @_;

return $sum;
}

1;

__END__
