use Test;
BEGIN { plan tests => 4 };
use strict;

use Decision::Table;

ok(1);

		# "Decision::Table::Action-oriented" Decision Table

	my $dt = Decision::Table::Partial->new(

		conditions =>
		[
			Decision::Table::Condition->new( text => 'schnell gefahren ?' ),      # 0
			Decision::Table::Condition->new( text => 'Alkohol getrunken ?' ),     # 1
			Decision::Table::Condition->new( text => 'kontrolliert Polizei ?' ),  # 2
		],

		actions =>
		[
			Decision::Table::Action->new( text => 'gebuehrenpflichtige Verwarnung' ), # 0
			Decision::Table::Action->new( text => 'Fuehrerschein Entzug' ),           # 1
			Decision::Table::Action->new( text => 'nichts geschieht' )                # 2
		],

		rules =>
		[
			Decision::Table::Rule::Indexed->new( true => [ 0, 1 ], actions => [ 0 ] ),
			Decision::Table::Rule::Indexed->new( true => [ 1, 2 ], actions => [ 0, 1 ] ),
			Decision::Table::Rule::Indexed->new( true => [ 0, 1, 2 ], actions => [ 2 ] ),
		],
	);

ok(1);

    print $dt->to_text();

ok(1);

    print $dt->to_code();

ok(1);
