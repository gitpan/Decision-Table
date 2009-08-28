package Decision::Table::Condition;

    Class::Maker::class
    {
        public =>
        {
            string => [qw( id text )],
		    
	    bool => [qw( expected )],
        },
    };

=head1 Decision::Table::Condition

The class representing a condition. Various type of conditions are imaginable, but a few are implemented. I turned to use code conditions.

=cut

package Decision::Table::Condition::WithCode;

    Class::Maker::class
    {
        isa => [qw( Decision::Table::Condition )],
        
        public =>
        {
            ref => [qw( cref )],
        },
    };

=head1 Decision::Table::Condition::WithCode

The class representing a condition with an attached coderef.

=head2 $c = Decision::Table::Condition::WithCode->new( cref => $coderef )

cref - coderef that is evaluated and then returns true or false.

=head2 $c->execute( @args )

Execute the coderef with C<@args> as their arguments.

=cut
    
    sub execute : method
    {
        my $this = shift;

	Carp::croak "nothing to execute (no coderef in cref" unless defined $this->cref;

#	print Data::Dump::dump @_;

	return 0 unless defined $this->cref;

	my $result = $this->cref->( @_ );

	return 0 unless $result;

	return $result;
    }

1;
