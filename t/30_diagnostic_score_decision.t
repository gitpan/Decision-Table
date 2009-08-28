use strict;
use Test;
BEGIN { plan tests => 3 };

use Decision::Table;
use Decision::Table::Diagnostic;
use IO::Extended;
use Data::Dump;

ok(1);

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
	
	$dtp = Decision::Table::Diagnostic::Combinations->new(

		conditions =>
		[
			Decision::Table::Condition->new( text => 'nadeln = ja' ),	            # C0
			Decision::Table::Condition->new( text => 'nadeln = nein' ),		    # C1
			Decision::Table::Condition->new( text => 'Rundliche Zapfen' ),		    # C2
			Decision::Table::Condition->new( text => 'Laengliche Zapfen' ),		    # C3
			Decision::Table::Condition->new( text => '-- haengend' ),		    # C4
			Decision::Table::Condition->new( text => '-- stehend' ),		    # C5
			Decision::Table::Condition->new( text => 'Lange Nadeln' ),		    # C6
			Decision::Table::Condition->new( text => 'Kurze Nadeln' ),		    # C7
			Decision::Table::Condition->new( text => '-- eher scheitelfoermig' ),	    # C8
			Decision::Table::Condition->new( text => '-- rundum' ),			    # C9
			Decision::Table::Condition->new( text => 'Rissige oder geborstene Rinde' ), # C10
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
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '+++ +++ +++ --- --- --- --- --- --- ---', actions => [ 0 ] ), # Kiefer
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '--- --- --- +   +   +   +   +   +   +  ', actions => [ 1 ] ), # Tanne
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '+++                                    ', actions => [ 2 ] ), # Fichte
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '-   +   +                              ', actions => [ 3 ] ), # Eiche
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '    --- +++                            ', actions => [ 4 ] ), # Buche
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '+++ -   -                              ', actions => [ 5 ] ), # Linde
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '-   +   ++                             ', actions => [ 6 ] ), # Esche
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '    ++  -                              ', actions => [ 7 ] ), # Birke
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '                --                     ', actions => [ 8 ] ), # Ahorn
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '+++ +++ +++ --- --- --- --- --- --- ---', actions => [ 9 ] ), # Kastanie
		 Decision::Table::Rule::Combination::PlusMinus->new( code => '+++ +++ +++ --- --- --- --- --- --- ---', actions => [ 10 ] ),# Muratze :)
		],

		else => [ 10 ],
	);

        my $attributes = '    ++  -                              ';

         # I have a patient, give him diagnosis

	printfln "\nDIAGNOSIS for %S\n", $attributes;

println Data::Dump::dump $dtp->rules;

         #C0  C1  C2  C3  C4  C5  C6  C7  C8  C9
println "DISTANCE STATS: ", Data::Dump::dump my $results = $dtp->score( $attributes );

ok( 11 == @$results );

	printfln "Rangliste: (distance to patient with attributes %S \n\n", $attributes;
	
	$dtp->score_to_text( $results );

        $dtp->analyse( );

println "\n\nSCORE ALL";

#println Data::Dump::dump
 $dtp->score_all( $0."_score_all_data" );
	
ok( -e $0."_score_all_data" );

	
