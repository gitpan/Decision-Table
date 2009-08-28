package Decision::Table::Context;

	Class::Maker::class
	{
		public =>
		{
			string => [qw( text )],
		},
	};

=head1 Decision::Table::Context

The class representing a context. 

=head2 $ctx = Decision::Table::Context->new( text => $text )

text - an arbitrary text

=head2 $ctx->analyse

Reserved.

=cut

sub analyse : method
{
}

1;
