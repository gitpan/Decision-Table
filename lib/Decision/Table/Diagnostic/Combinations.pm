package Decision::Table::Diagnostic::Combinations;

use strict;
use warnings;

our $DEBUG = 0;

    Class::Maker::class
    {
        isa => [qw( Decision::Table )],
    };

sub _postinit
{
	my $this = shift;
}

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

=head2 decide

[
  {
    DISTANCE => 29,
    DISTANCE_DETAILS => [3, 1, 4, 3, 3, 3, 3, 3, 3, 3],
    RULE => bless({
          actions => [0],
          code => "+++ +++ +++ --- --- --- --- --- --- ---",
          id => 0,
          translated => [3, 3, 3, -3, -3, -3, -3, -3, -3, -3],
        }, "Decision::Table::Rule::Combination::PlusMinus"),
  },
  {
    DISTANCE => 17,
    DISTANCE_DETAILS => [3, 5, 2, 1, 1, 1, 1, 1, 1, 1],
    RULE => bless({
          actions => [1],
          code => "--- --- --- +   +   +   +   +   +   +  ",
          id => 1,
          translated => [-3, -3, -3, 1, 1, 1, 1, 1, 1, 1],
        }, "Decision::Table::Rule::Combination::PlusMinus"),
  },
  {
    DISTANCE => 6,
    DISTANCE_DETAILS => [3, 2, 1, 0, 0, 0, 0, 0, 0, 0],
    RULE => bless({
          actions => [2],
          code => "+++                                    ",
          id => 2,
          translated => [3, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        }, "Decision::Table::Rule::Combination::PlusMinus"),
  },
  {
    DISTANCE => 4,
    DISTANCE_DETAILS => [1, 1, 2, 0, 0, 0, 0, 0, 0, 0],
    RULE => bless({
          actions => [3],
          code => "-   +   +                              ",
          id => 3,
          translated => [-1, 1, 1, 0, 0, 0, 0, 0, 0, 0],
        }, "Decision::Table::Rule::Combination::PlusMinus"),
  },
  {
    DISTANCE => 9,
    DISTANCE_DETAILS => [0, 5, 4, 0, 0, 0, 0, 0, 0, 0],
    RULE => bless({
          actions => [4],
          code => "    --- +++                            ",
          id => 4,
          translated => [0, -3, 3, 0, 0, 0, 0, 0, 0, 0],
        }, "Decision::Table::Rule::Combination::PlusMinus"),
  },

..
]

=cut

sub score : method
{
	my $this = shift || die;
	
	my $patient = shift || die; 
		
	my $results=[];


	foreach ( Data::Iter::iter $this->rules )
	{
	    my $res = $results->[$_->COUNTER] = {};

	    $res->{RULE_ID} = $_->VALUE->id;

	    $res->{RULE} = $_->VALUE;

	    $res->{DISTANCE_DETAILS} = $_->VALUE->distance( $patient );
	    
	    $res->{DISTANCE} = $_->VALUE->distance_sum( $patient );
	}

	return $results;
}

sub score_all : method
{
	my $this = shift || die;

	my $file = shift;

	use IO::File;

	my $fh = new IO::File ">$file" or die "$!: $file";
		
	my $results={};

	$fh->print( join( "\t", qw(SRC DST SRC_NAME DST_NAME distance) ), "\n" ) if $fh;

	foreach my $r ( Data::Iter::iter $this->rules )
	{
	    $results->{CODES}->[$r->COUNTER] = $r->VALUE->code;

	    my $scores = $this->score( $r->VALUE->code );

	    push @{ $results->{TABLE} }, { RULE_ID => $r->VALUE->id, scores => $scores  };

	    for my $s ( Data::Iter::iter $scores )
	    {
		 # map { $r->text } $r->VALUE->actions_as_objs( $this )
		$fh->print( 
		    join( "\t", 
			  $r->VALUE->id, 
			  $s->VALUE->{RULE_ID}, 
			  join(':',map {$_->text } $r->VALUE->actions_as_objs($this) ), 
			  join(':',map {$_->text } $s->VALUE->{RULE}->actions_as_objs($this) ), 
			  $s->VALUE->{DISTANCE} 
		    ), 
		    "\n" 
		    ) if $fh;
	    }
	}

	$fh->close() if $fh;

	return $results;
}

=head2 $dt->score_to_text( $results )

Formats and print he href from C<$dt-E<gt>score> as a human readible text.


translates

  {
    DISTANCE => 9,
    DISTANCE_DETAILS => [0, 5, 4, 0, 0, 0, 0, 0, 0, 0],
    RULE => bless({
          actions => [4],
          code => "    --- +++                            ",
          id => 4,
          translated => [0, -3, 3, 0, 0, 0, 0, 0, 0, 0],
        }, "Decision::Table::Rule::Combination::PlusMinus"),
  },

to

=cut

sub score_to_text : method
{
	my $this = shift;
	
	my $score_output = shift;


	my $result;

=head1

  $array_ref =
     [
     tcf1 => 28.44
     tcf1 => 28.13
     tcf3 => 26.92
     tcf3 => 26.09
     gapdh => 17.08
     gapdh => 16.1
     ];

 Then a call

   transform_array_to_hash( $array_ref )

 will return this hash

  {
    gapdh => ["17.08", "16.1"],
    tcf1  => ["28.44", "28.13"],
    tcf3  => ["26.92", "26.09"],
  }

=cut

	foreach ( Data::Iter::iter $score_output )
	{
	    for my $aobj ( Data::Iter::iter [ $_->VALUE->{RULE}->actions_as_objs( $this ) ] )
	    {
		push @$result, ( $_->VALUE->{DISTANCE} => $aobj->VALUE->text );

		IO::Extended::printfln "%d) distance=%d to action=%S", $aobj->COUNTER, $_->VALUE->{DISTANCE}, $aobj->VALUE->text if $DEBUG;
	    }
	}
	
	print Data::Dump::dump "before transform score_output result: ", $result if $DEBUG;
	
	print Data::Dump::dump "after transform: ", Data::Iter::transform_array_to_hash( $result ) if $DEBUG;

	IO::Extended::println "Distances to object in question:\n ", Data::Dump::dump Data::Iter::transform_array_to_hash( $result );

	print "\n";
}

sub analyse : method
{
	my $this = shift;
	
	for my $r ( Data::Iter::iter $this->rules )
	{	
		my $results = $this->score( $r->VALUE->code );
	
		IO::Extended::printfln "Rule %d, actions=%s", $r->COUNTER, join( ', ', map { $_->text } $r->VALUE->actions_as_objs( $this ) );

		$this->score_to_text( $results );		
	}
}

1;

__END__

=head1 NAME

Decision::Table::Diagnostic::Combinations - make diagnostic decisions on combinations of attributes

=head1 SYNOPSIS

  use Decision::Table;

  use Decision::Table::Diagnostic;

  sub score
  {
      my $string = shift;
      
      my $val;
      
      $val += ( { '+' => 1, '-' => -1 }->{$_} || 0 ) foreach split //, $string; 
      
      return $val;
  }

  sub digest
  {
      my $encoded = shift || die;
      
      return [ map { score( $_ ) } ( $encoded =~ m/(...)\s?/g ) ];
  }

  our $dtp;
    
 # Diagnosis Score
 #
 # In a Diagnosis Score Table the Decision Table 'actions' are diagnosis.
 #
 # We have a homologe scores:
 #
 # +++ = 3 (absolutely sure)
 # ++ = 2 (yes, yes)
 # + = 1 (yes)
 #   = 0 (indifferent)
 # - = -1 (no)
 # -- = -2 (no, no)
 # --- = -3 (definitifly not)

  $dtp = Decision::Table::Diagnostic->new(
					  
					  conditions =>
					  [
					   Decision::Table::Condition->new( text => 'nadeln = ja' ),			# C0
					   Decision::Table::Condition->new( text => 'nadeln = nein' ),			# C1
					   Decision::Table::Condition->new( text => 'Rundliche Zapfen' ),		# C2
					   Decision::Table::Condition->new( text => 'Laengliche Zapfen' ),		# C3
					   Decision::Table::Condition->new( text => '-- haengend' ),			# C4
					   Decision::Table::Condition->new( text => '-- stehend' ),			# C5
					   Decision::Table::Condition->new( text => 'Lange Nadeln' ),			# C6
					   Decision::Table::Condition->new( text => 'Kurze Nadeln' ),			# C7
					   Decision::Table::Condition->new( text => '-- eher scheitelfoermig' ),		# C8
					   Decision::Table::Condition->new( text => '-- rundum' ),			# C9
					   Decision::Table::Condition->new( text => 'Rissige oder geborstene Rinde' ),	# C10
					   ],
					  
					  actions =>
					  [
					   Decision::Table::Action->new( text => 'Kiefer' ),
					   Decision::Table::Action->new( text => 'Tanne' ),
					   Decision::Table::Action->new( text => 'Fichte' ),
					   Decision::Table::Action->new( text => 'Eiche' ),
					   Decision::Table::Action->new( text => 'Buche' ),
					   Decision::Table::Action->new( text => 'Linde' ),
					   Decision::Table::Action->new( text => 'Esche' ),
					   Decision::Table::Action->new( text => 'Birke' ),
					   Decision::Table::Action->new( text => 'Ahorn' ),
					   Decision::Table::Action->new( text => 'Kastanie' ),
					   Decision::Table::Action->new( text => 'Muratze' ),
					   Decision::Table::Action->new( text => 'Unbekannt' ),
					   ],
					  
					  rules =>
					  [
					   #C0  C1  C2  C3  C4  C5  C6  C7  C8  C9 
					   digest( '+++ +++ +++ --- --- --- --- --- --- ---' ) => [ 0 ],	 # Kiefer
					   digest( '--- --- --- +   +   +   +   +   +   +  ' ) => [ 1 ],	 # Tanne
					   digest( '+++                                    ' ) => [ 2 ],	 # Fichte
					   digest( '-   +   +                              ' ) => [ 3 ],	 # Eiche
					   digest( '    --- +++                            ' ) => [ 4 ],	 # Buche
					   digest( '+++ -   -                              ' ) => [ 5 ],	 # Linde
					   digest( '-   +   +                              ' ) => [ 6 ],	 # Esche
					   digest( '    ++  -                              ' ) => [ 7 ],	 # Birke
					   digest( '                --                     ' ) => [ 8 ],	 # Ahorn
					   digest( '+++ +++ +++ --- --- --- --- --- --- ---' ) => [ 9 ],	 # Kastanie
					   digest( '+++ +++ +++ --- --- --- --- --- --- ---' ) => [ 10 ],        # "Muratze" ;)
					   ],
					  
					  else => [ 10 ],
					  );

   # I have a patient, give him diagnosis

                           #C0  C1  C2  C3  C4  C5  C6  C7  C8  C9
  print "\nDIAGNOSIS for '    ++  -                              '\n";

                                                   #C0  C1  C2  C3  C4  C5  C6  C7  C8  C9
  print Dumper my $results = $dtp->decide( digest( '    ++  -                              ' ) );
	
  print "Rangliste:\n\n";
	
  $dtp->score_to_text( $results );

  # Lets look who is similar (DIFFERENTIAL DIAGNOSIS) to each other
  # and we could even detect identical diagnosis

  $dtp->analyse();

=head1 DESCRIPTION

Make diagnosis from knowledge (of an expert). In essence the technique is similar to an expert system or markov believe networks. The simple data structure is but far more easier to maintain (and to understand). 
Through computation of probilistic values you become a picture which diagnosis is the best (or better which set of diagnosis is the most probalistic ones). The above synopsis (in german) outlines the recognition of trees by their leafs, envelope and fir-cones etc.

=head1 Decision::Table::Partial

This is a decision table that has an addtional attribute C<else>. If all conditions fail than this actions will be called.

 else => [ 0, 5, 2 ]

for example would call action 0, 5, and 2 if no conditions matched.

=head1 METHODS

=head2 $dt = Decision::Table::Diagnostic->new( conditions => [], actions => [], rules => [] )

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
the actions called when no rule applied (attests that this is a B<partial> decision table)

=back

=head2 $dt->decide( $patient )

This method computes the highscore of comulative probalistic values (by comparing to a given C<$patient>). It returns a href with a table of following scheme

 {
    $score => [ $action_id, $action_id,  ... ],
 }

[DE Ziel: Suche die Evtl. Decision::Table::Actions herraus die am wenigsten "Abstand" (mengen_differenz) zu unserem "Patienten" haben].

Imagine you found a tree with following attributes (encoded by + and -, see synopsis)

  digest( '    ++  -                              ' )

and want to retrieve the highscore of the probabilistic of type.

	print Dumper my $results = $dtp->decide( digest( '    ++  -                              ' ) );

This would print the highscore as a raw perl hash.

=head2 $dt->analyse;

Analyses the virgin $dt and displays informative text. It prints how C<far> away (or near) the expected diagnoses are (in terms of problabilistic values), so one can get a picture which diagnosis will B<always> be very close to each other. So from the synopsis it would print

 Rangliste:

 0 => Birke
 4 => Eiche, Esche
 5 => Ahorn
 6 => Fichte, Linde
 9 => Buche
 17 => Tanne 
 29 => Kiefer, Kastanie, Muratze

 Who is similar to Kiefer ?
 0 => Kiefer, Kastanie, Muratze
 27 => Fichte 
 28 => Ahorn
 29 => Eiche, Linde, Esche, Birke
 30 => Buche
 46 => Tanne

 Who is similar to Tanne ?
 0 => Tanne
 16 => Buche
 17 => Eiche, Linde, Esche, Birke
 18 => Ahorn
 19 => Fichte
 46 => Kiefer, Kastanie, Muratze

 Who is similar to Fichte ?
 0 => Fichte
 2 => Linde
 5 => Ahorn
 6 => Eiche, Esche, Birke
 9 => Buche
 19 => Tanne
 27 => Kiefer, Kastanie, Muratze

 Who is similar to Eiche ?
 0 => Eiche, Esche
 4 => Birke
 5 => Ahorn
 6 => Fichte
 7 => Buche
 8 => Linde
 17 => Tanne
 29 => Kiefer, Kastanie, Muratze

 Who is similar to Buche ?
 0 => Buche
 7 => Eiche, Esche
 8 => Ahorn
 9 => Fichte, Linde, Birke
 16 => Tanne
 30 => Kiefer, Kastanie, Muratze

 ...


=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Ünalan, E<lt>muenalan@cpan.orgE<gt>

=head1 SEE ALSO

L<Decision::Table::Diagnostic>, L<Decision::Table::Wheighted>

=head1 REFERENCES

<1> Book (German): M. Rammè, "Entscheidungstabellen: Entscheiden mit System" (Prentice Hall))
