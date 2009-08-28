package Decision::Table::Action;

	Class::Maker::class
	{
		public =>
		{
			string => [qw( text id )],
		},
	};

=head1 Decision::Table::Action

The class representing an action.

=head2 $a = Decision::Table::Action->new( text => $text, id => $id )

text - an arbitrary text
id   - the array index as given within the C<$dt-E<gt>actions> aref.

=cut

sub execute : method
{
    my $this = shift;

}

package Decision::Table::Action::WithCode;

	Class::Maker::class
	{
	    isa => [qw( Decision::Table::Action )],
	    
		public =>
		{
			ref => [qw( cref )],
		},
	};

=head1 Decision::Table::Action::WithCode

Decision::Table::Action with attached code for execution.

=head2 $a = Decision::Table::Action::WithCode->new( cref => $coderef )

cref - a coderef to a perl function that gets executed

=head2 $a->execute( @args )

The $coderef is called with @args.

=cut

    sub execute : method
    {
        my $this = shift;

    return $this->cref->( @_ ); 
    }

1;
