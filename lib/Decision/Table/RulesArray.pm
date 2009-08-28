package Decision::Table::RulesArray;

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
 
return $this->rules;
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
