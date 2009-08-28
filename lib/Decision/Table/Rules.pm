package Decision::Table::Rules;

our $VERSION = '0.01';

	Class::Maker::class
	{
		public =>
		{
			array => [qw( rules )],
		},
	};

sub as_objects : method 
{
    my $this = shift;
 
    my $class_rule = shift || 'Decision::Table::Rule::Indexed';
        

    my @result = ();

    for( my $i=0; $i < @{ $this->rules }; $i+=2 )
    {
	my ( $conditions, $actions ) = @{ $this->rules }[$i, $i+1];

	push @result, $class_rule->new( conditions => $conditions, actions => $actions);
    }

return @result;
}

sub as_indexed_objects : method
{
    my $this = shift;

return $this->as_objects( 'Decision::Table::Rule::Indexed' );
}

sub as_serial_objects : method
{
    my $this = shift;

return $this->as_objects( 'Decision::Table::Rule::Serial' );
}

1;
