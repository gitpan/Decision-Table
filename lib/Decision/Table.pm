use 5.006;

use strict;
use warnings;

BEGIN 
{
        # this is the worst damned warning ever, so SHUT UP ALREADY!
        $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /used only once/ }; 
}

use Class::Maker;

use Class::Maker::Types::Array;

use IO::Extended qw(:all);

use Math::Matrix;

use Tie::RefHash;

use IO::Extended qw(:all);

use Data::Dump;

use Data::Iter qw(:all);

use Generator::Perl;

use Decision::Table::Rule;
use Decision::Table::Context;
use Decision::Table::Partial;
use Decision::Table::Condition;
use Decision::Table::Action;
use Decision::Table::Rules;
use Decision::Table::RulesArray;
use Decision::Table::Rule::Indexed;
use Decision::Table::Rule::Serial;
use Decision::Table::Rule::Combination::PlusMinus;
use Decision::Table::Diagnostic::Combinations;
use Decision::Table::Compact;

package Decision::Table;

use IO::Extended qw(:all);

use Data::Dump qw(dump);

    our $VERSION = '0.02_02';
    
    sub DEBUG { 0 }

=head1 NAME

Decision::Table - decisions made easy

=head1 SYNOPSIS

  use Decision::Table;

    # A "complete" Decision::Table

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
      
      # expectation rule table
      
      rules =>
      [
       [ 1, 0, 1 ] => [ 0 ],
       [ 1, 1, 1 ] => [ 0, 1 ],
       [ 0, 0, 0 ] => [ 2 ],
      ],
  );

  $dt->condition_find( 1, 0, 1 );  # returns ( [ 0 ] )

  $dt->condition_find( 1, 1, 1 );  # returns ( [0, 1 ] )

  $dt->decide( 0, 1, 0 );  # returns undef because no condition matches 

  $dt->decide( 1, 1, 1 );  # dispatches action ( 0, 1 ) - here it just prints @$actions->[0, 1]

  $dt->to_text;

=head1 DESCRIPTION

When you have multiple conditions (i.e. if statements) which lead to some sort of actions, you can use
a decision table. It helps you to dissect, organize and analyse your problem and keeps your code very concise.
Especially complex and nested if/else/elsif paragraphs can be hard to mantain, understand and therefore predestinated 
to semantic and syntactic errors. But this is not the only application for decision tables, rather it can be utilized
for various sorts of problems: cellular automata (Wolfram type), markov believe networks, neuronal networks and more.

This module supports the generation of:

	- complete (totalistic)
	- limited
	- nested
	- stochastic
	- diagnosis score
	- heuristic

decision tables. It also has some ability to analyse your decision table and give hints about your design (<1>, which
also inspired me to this module and some examples). 

=head1 PROS AND CONS

The processing of a decision table can cost some cpu-overhead. The decision table can be converted to static perl code, to
solve this problem. Because the static code cannot be automatically reverse engineered (not yet, but hopefully in future),
this would cost you some flexibility in modifying the decision table in place.

=head1 COMPLETE VS PARTIAL TABLES

The term "complete" decision table means that every combination of conditions is explicitly assigned some action.
The term "partial" decision table means that not every combination of conditions is explicitly assigned some action. These table have an additional attribute called C<else> that holds the default action (if no other was found for the given combination of conditions).

=head1 RULE TABLES

Two general different rule table structures are use within this package. It is handy to distinguish them and it also prevents some ambigousity.

=head2 SERIAL RULE TABLE (Decision::Table::Rule::Serial)

It has following data schema:

    [ condition_0_expected, condition_1_expected, condition_2_expected, ... ] => [ action_id, action_id, action_id ]

as seen here

    rules =>
    [
      [ 1, 0, 1 ] => [ 0 ],
      [ 1, 1, 1 ] => [ 0, 1 ],
      [ 0, 0, 0 ] => [ 2 ],
    ],

The "expected" means 0 for false and 1 for true (of course). So that C<[ 1, 0, 1 ] =E<gt> [ 0 ]> is tested as

  condition_0_expected is expected true 
  condition_1_expected is expected false
  condition_2_expected is expected true

the action 

 action_id 0 

is dispatched. What "dispatch" means is dependant on the action type (text displayed, code executed, ...).

=head2 INDEX RULE TABLE (Decision::Table::Rule::Indexed)

It uses condition indices and has following data schema:

    [ index_condition_expected_true, index_condition_expected_true, ... ] => [ action_id, action_id, action_id ]

    rules =>
    [
      [ 3, 4 ] => [ 0 ],
      [ 1, 2 ] => [ 0, 1 ],
      [ 3 ]    => [ 2 ],
    ],

Note: It is allowed to have rundadant condition rules. That means you may have different actions with same conditions.

=head1 METHODS AND ATTRIBUTS

=cut    

        Class::Maker::class
        {
            public =>
            {
                array => [qw( conditions actions else )],
	     
	        obj =>  [qw( rules )],	     

	        bool => [qw( rules_serial )],
            },
        };

sub _postinit : method
{
  my $this = shift;

  for( qw( rules conditions actions ) )
  {
      my $what = $this->$_;

      for( Data::Iter::iter $what )
      {
	  $_->VALUE->id( $_->COUNTER );
      }
  }

return $this;
}

=head2 $dt = Decision::Table->new( conditions => [], actions => [], rules => [] );

The conditions and actions arguments take an aref with objects. The conditions take C<Decision::Table::Condition>, actions take C<Decision::Table::Action> objects.

		conditions =>
		[
			Decision::Table::Condition->new( text => 'drove too fast ?' ),
			Decision::Table::Condition->new( text => 'comsumed alcohol ?' ),
			Decision::Table::Condition->new( text => 'Police is making controls ?' ),
		],

		actions =>
		[
			Decision::Table::Action->new( text => 'charged admonishment' ),		# 0
			Decision::Table::Action->new( text => 'drivers license cancellation' ),	# 1
			Decision::Table::Action->new( text => 'nothing happened' )		# 2
		],

The rules arguments takes an aref for boolean algebra. It is like a hash. Which actions should be taken when which conditions are true? It has following structure:

			# Decision::Table::Conditions => Decision::Table::Actions

		rules =>
		[
			[ 1, 0, 1 ] => [ 0 ],
			[ 1, 1, 1 ] => [ 0, 1 ],
			[ 0, 0, 0 ] => [ 2 ],
		],

The rules hold an L<SERIAL RULE TABLE>. The left (key) array represents the boolean combination.

  [ 1, 0, 1 ]

stands for

  $dt->condition->[0] must be true
  $dt->condition->[1] must be false
  $dt->condition->[2] must be true

then action is aref to a list of actions. So

  [ 0 ]

stands for

  $dt->action->[0]

is taken. The action list may be redundant. The order of action is preserved during calls.

=head2 $dt->rules_as_objs 

After the constructor was called the 

 $r = $dt->rules_as_objs

attribute holds a L<Decision::Table::Rules> object and not the aref of arefs.

Note: The rules object turns all index/serial rule tables into tables of object references.

 [ 0, 1, 2 ] =>  

becomes

 [ $sref_cond_0, $sref_cond_1, $sref_cond_2 ] => 

This is also true for the actions part.

=cut

sub rules_as_objs : method
{
  my $this = shift;
  
   # as_objects return Decision::Table::Rule->new( condition => , action => ) objects

  my $class_rules = 'Decision::Table::Rule::Indexed';
  
  $class_rules ='Decision::Table::Rule::Serial' if $this->rules_serial;
  
#  ln STDERR "rules_as_objs: ", scalar @{ $this->rules }, " of objects $class_rules\n";

  if( $this->rules->[0]->isa( 'UNIVERSAL' ) )
  {

      if( 0 )
      {
	  ln STDERR "HERE WE ARE: "
	      , dump( scalar $this->rules )
	      , "Rules Array: "
	      , dump Decision::Table::RulesArray->new( rules => scalar $this->rules )->as_objects;
      }
      
      return Decision::Table::RulesArray->new( rules => scalar $this->rules )->as_objects;
  }

return Decision::Table::Rules->new( rules => scalar $this->rules )->as_objects( $class_rules );
}


=head2 $dt->lookup( $type )

This is a helper method that eases access to conditions and actions.

  $dt->lookup( 'actions', 0, 1, 2 );

returns action 0, 1, and 2.

=cut

    sub lookup : method
    {
        my $this = shift;
    
        my $type = shift;
    
    return @{ $this->$type }[ @_ ];
    }

=head2 $dt->condition_find( $aref_conditions )
    
Finds the actions that match B<exactly> the condition part. Returns a list of actions aref (multiple because multiple conditions with different actions are allowed).

=cut

    sub condition_find : method
    {
        my $this = shift;


	my @result;
    
        foreach my $r ( @{ $this->rules_as_objs } )
        {
	    if( $r->true_false_compare( scalar @{ $this->conditions }, @_ )->[0] == 1 )
	    {    
		if( DEBUG() )
		{
		    ln STDERR "TRUE_FALSE_COMPARE: ", Data::Dump::dump $r->true_false_compare( scalar @{ $this->conditions }, @_ );
		}

		push @result, $r; #scalar $r->actions;
	    }
        }
    
    return @result;
    }

our $Tidy = 0;

=head2 $Decision::Table::Tidy (default: 0)

A global variable that controls if the genereated code by C<to_code> is tidied up with Perl::Tidy and printed before execution.

=head2 $dt->to_code
    
Returns perl code that represents the logic of the decision table. Returns a list or text as tested by

 wantarray ? @buffer : join "\n", @buffer;

=cut
    
    sub to_code : method
    {
        my $this = shift;

#	for( qw(true false) )
#	{
	    my $mtx = Math::PermMatrix->new( dimension => scalar @{ $this->conditions } );
	    
	    
	    my $g = bless [], 'Generator::Perl';
	    
	    my $code;
	    
	    $code .= 'unless( ref( $this ) ){ die "throw an exception"; }';
	    
	    # transpose through all possibilities of the dimension 

	    foreach my $line ( @{ $mtx->transposed } )
	    {
		#::printfln "Matrix line %s", join( '', @$line );

		if( DEBUG() )
		{
		    ln STDERR "CONDITION FIND ", dump( $line );
		}

		# return rules that match the combination
		if( my @rules = $this->condition_find( true => $line ) )
		{
		    foreach my $rule ( @rules )
		    {
			if( DEBUG() )
			{
			    ln STDERR "\tFOUND: ", dump( $rule, $rule->actions_as_objs($this) );
			}

			my @terms;

			if( DEBUG() )
			{
			    ln STDERR "\tTRANSPOSE: ", dump( \@$line );
			}
			
			foreach ( Data::Iter::iter \@$line )
			{
			    my $pass_or_fail = $_->VALUE ? 'enclose' : 'not';
			    
			    push @terms, $g->$pass_or_fail( $this->conditions->[ $_->COUNTER ]->text );
			}

#			lnf STDERR "\CODEGEN: TERMS %s", dump( \@terms );

#			lnf STDERR "\CODEGEN ELSIF:  %s", $g->elsif( $g->and( @terms ) );

			$code .= $g->elsif( $g->and( @terms ) );

#			lnf STDERR "\CODEGEN ACTIONS:  %s", join( ';', map { $_->text } $rule->actions_as_objs($this) );

			$code .= $g->block( join( ';', map { $_->text } $rule->actions_as_objs($this) ) );
		    }
		}
	    }
	    
	    $code .= $g->else;
	    
	    $code .= $g->block( map { $_->text.';' } $this->lookup( 'actions', @{ $this->else } ) );
	    
#	}

	if( 1 ) #$Tidy )
	{
	    use Perl::Tidy;
	    
	    Perl::Tidy::perltidy( 
		source => \$code,
		destination => \$code,
		);
	}

	return $code;
    }
    
=head2 $dt->to_code_and_execute

Runs the decision table (via generation code by C<to_code>) and evaluating. The actions get actually executed ! The method dies when the code evaluation results in a filled C<$@>.

  my $h = Human->new( hairs => 'green', shorts => 'dirty' );

  use Data::Dumper;

  print Dumper $dt->to_code_and_execute( $h );

=cut

    sub to_code_and_execute
    {
        my $this = shift;
    
        my $candidate = shift;
    
            my $code = $this->to_code();
    
            eval $code;
    
            die $@ if $@;
    
            if( $Tidy )
            {
                use Perl::Tidy;
    
		Perl::Tidy::perltidy( 
		    source => \$code,
		    destination => \$code,
		    );
            }
            
    return $candidate, $code;
    }

=head2 $dt->decide

Returns a hash containing C<'pass'> | C<'fail'>. This is the overall interpretation of the conditions. This means it will have the key C<'fail'> if at least one condition failed and C<'pass'> respectively.

=cut

    sub decide : method
    {
	my $this = shift;

	return { reverse %{ $this->table( @_ ) } };
    }

=head2 $dt->table

Returns a complete table of the condition status. The format is 

 $condition_id => action_result 

where the action result is often true | false.

 {
   '1' => false,
   '0' => true,
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
    
#                unless( exists $result->{ '' } || exists $result->{ 0 } ) 
#                {
#                    $r->execute( @args ) for $this->lookup( 'actions', @$actions );
#                }

    return $result;
    }

=head2 $dt->to_text

Prints a nice table which is somehow verbosly showing the rules.

=cut

sub rule_to_text : method
{
    my $this = shift || Carp::croak;

    my $rule = shift;

    my $out = "";

		for( Data::Iter::iter [ $rule->conditions_as_objs( $this ) ] )
		{
		    $out .= IO::Extended::sprintfl "if condition (#%d) with id=%d is as expected=[%s] : text=%S     [last result: %S]\n", 
		    $_->COUNTER, 
		    $_->VALUE->id, 
		    $_->VALUE->expected ? 'true' : 'false', 
		    $_->VALUE->text,
		    defined $rule->_true_false_results->[$_->COUNTER] ? $rule->_true_false_results->[$_->COUNTER] : "undef"
		    ;
		}

                 $out .= "=="x70;

                 $out .= "\n";
    
                 $out .= IO::Extended::sprintfln "TRUE: %S",$rule->results_last_all_true?'yes':'no';
                 $out .= "then do actions: ".$_->text."\n" for $rule->actions_as_objs( $this );
                 $out .= "\n";

    return $out;
}
    
    sub to_text
    {
        my $this = shift;

	
	my $out = '';
	
            foreach my $r ( $this->rules_as_objs )
            {
#	      print Data::Dump::dump $r, "\n";	      

		$out .= $this->rule_to_text( $r );
            }

	return $out;	
    }

package Math::PermMatrix;

	Class::Maker::class
	{
		public =>
		{
			int => [qw( dimension )],
		}
	};

sub transposed
{
	my $this = shift;

return _genmatrix( $this->dimension )->transpose;
}

sub _genmatrix
{
	my $rulcnt = shift;

	my @matrix;

	foreach my $counter ( reverse ( 1 .. $rulcnt ) )
	{
		my @re = _gencomb( $counter, 3 );

		for( my $c=0; $c<2**$rulcnt/@re; $c++ )
		{
			push @{ $matrix[$counter-1] }, @re;
		}
	}

return Math::Matrix->new(@matrix);
}

sub _gencomb
{
	my ( $lauf, $wdh ) = @_;

	my $cnt;

	my @result;

	foreach ( 1..$wdh-1 )
	{
		my $ja = ( $cnt++ % 2 );

		foreach (1..2**($lauf-1))
		{
			push @result, $ja ? '0' : '1';
		}
	}

return @result;
}
	
1;

__END__

=head1 FAUNA AND FLORA OF DECISION TABLES

I personally differentiate between "action-oriented" and "categorizing" decision tables.

=head2 "action-oriented" decision tables

Decision::Table::Conditions-dependently actions are taken to do something. In the synopsis you see an example for this:

	my $dt = Decision::Table->new(

		conditions =>
		[
			Decision::Table::Condition->new( text => 'drove too fast ?' ),
			Decision::Table::Condition->new( text => 'comsumed alcohol ?' ),
			Decision::Table::Condition->new( text => 'Police is making controls ?' ),
		],

		actions =>
		[
			Decision::Table::Action->new( text => 'charged admonishment' ),			# 0
			Decision::Table::Action->new( text => 'drivers license cancellation' ),	# 1
			Decision::Table::Action->new( text => 'nothing happened' )				# 2
		],
			# Decision::Table::Conditions => Decision::Table::Actions

		rules =>
		[
			[ 1, 0, 1 ] => [ 0 ],
			[ 1, 1, 1 ] => [ 0, 1 ],
			[ 0, 0, 0 ] => [ 2 ],
		],
	);

	$dt->analyse();

=head2 "categorizing" decision tables

Here we are making decisions about categorizing (classifying) something. The "Decision::Table::Actions" are mainly more
annotating something.

	my $dtp = Decision::Table->new(

		conditions =>
		[
			Decision::Table::Condition->new( text => '$this->hairs eq "green"' ),
			Decision::Table::Condition->new( text => '$this->income > 10*1000' ),
			Decision::Table::Condition->new( text => '$this->shorts eq "dirty"' ),
		],

		actions =>
		[
			Decision::Table::Action->new( text => '$this->name( "freak" );' ),
			Decision::Table::Action->new( text => '$this->name( "dumb" )' ),
			Decision::Table::Action->new( text => '$this->name( "geek" )' ),
			Decision::Table::Action->new( text => '$this->name( "<unknown>" )' ),
		],

		rules =>
		[
			[ 1, 1, 1 ] => [ 2, 1 ],
			[ 0, 0, 1 ] => [ 1 ],
			[ 1, 0, 1 ] => [ 0 ],
			[ 0, 1, 1 ] => [ 0 ],
		],

		else => [ 3 ],
	);

=head1 EXAMPLE "Decision::Table::Action-oriented" decisions

    my $dt = Decision::Table::Partial->new(

    conditions =>
    [
    Decision::Table::Condition->new( text => 'schnell gefahren ?' ),
    Decision::Table::Condition->new( text => 'Alkohol getrunken ?' ),
    Decision::Table::Condition->new( text => 'kontrolliert Polizei ?' ),
    ],
    
    actions =>
    [
    Decision::Table::Action->new( text => 'gebuehrenpflichtige Verwarnung' ),
    Decision::Table::Action->new( text => 'Fuehrerschein Entzug' ),
    Decision::Table::Action->new( text => 'nichts geschieht' )
    ],
    
    rules =>
    [
    [ 0, 1 ] => [ 0 ],
    [ 1, 2 ] => [ 0, 1 ],
    [ 0, 1, 2 ] => [ 2 ],
    ],
    );

    $dt->to_text();

=head1 EXAMPLE  "categorizing" decisions

    my $dtp = Decision::Table::Partial->new(
    
    conditions =>
    [
    Decision::Table::Condition::WithCode->new( text => '$this->hairs eq "green"', cref => sub { $_[0]->hairs eq "green" } ),
    Decision::Table::Condition::WithCode->new( text => '$this->income > 10*1000', cref => sub { $_[0]->income > 10*1000 } ),
    Decision::Table::Condition::WithCode->new( text => '$this->shorts eq "dirty"', cref => sub { $_[0]->shorts eq "dirty" } ),
    ],
    
    actions =>
    [
    Decision::Table::Action::WithCode->new( text => '$this->name( "freak" )', cref => sub { $_[0]->name( "freak" ) } ),
    Decision::Table::Action::WithCode->new( text => '$this->name( "dumb" )', cref => sub { $_[0]->name( "dumb" ) } ),
    Decision::Table::Action::WithCode->new( text => '$this->name( "geek" )', cref => sub { $_[0]->name( "geek" ) } ),
    Decision::Table::Action::WithCode->new( text => '$this->name( "unknown" )', cref => sub { $_[0]->name( "unknown" ) } ),
    ],
    
    rules =>
    [
     [ 0, 1, 2 ] => [ 2, 1 ],
     [ 0, 2 ] => [ 1 ],
     [ 0, 1 ] => [ 0 ],
     [ 1, 2 ] => [ 0 ],
    ],
    
    else => [ 3 ],
    );

    class 'Human',
    {
      public =>
      {
         string => [qw( hairs name shorts)],
    
         integer => [qw( income )],
      },
    
      default =>
      {
         income => 0,
      },
    };

    my $this = Human->new( hairs => 'green', shorts => 'dirty' );
	
    print Dumper [ $dtp->decide( $this ) ];

    $this->income( 20*1000 );
    
    print Dumper [ $dtp->decide( $this ) ];

=head2 EXPORT

None by default.

=head1 AUTHOR

Murat Ünalan, E<lt>muenalan@cpan.orgE<gt>

=head1 SEE ALSO

L<Decision::Table::Diagnostic>, L<Decision::Table::Wheighted>

=head1 REFERENCES

<1> Book (German): M. Rammè, "Entscheidungstabellen: Entscheiden mit System" (Prentice Hall))
