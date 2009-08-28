use Test;
BEGIN { plan tests => 6 };
use strict;

use Decision::Table;

use IO::Extended qw(:all);

use Data::Dump qw(dump);

ok(1);

		# "Categorizing" Decision Table

	my $dtp = Decision::Table::Partial->new(

		conditions =>
		[
		 Decision::Table::Condition::WithCode->new( # 0
							    text => '$this->hairs eq "green"', 
							    cref => sub { $_[0]->hairs eq "green" } 
							    ),
		 Decision::Table::Condition::WithCode->new( # 1
							    text => '$this->income > 10*1000', 
							    cref => sub { $_[0]->income > 10*1000 } 
							    ),
		 Decision::Table::Condition::WithCode->new( # 2
							    text => '$this->shorts eq "dirty"', 
							    cref => sub { $_[0]->shorts eq "dirty" } 
							    ),
		],

		actions =>
		[
			Decision::Table::Action::WithCode->new( # 0 
							       text => '$this->nick( "freak" )', 
							       cref => sub { $_[0]->nick( "freak" ) } 
							      ),
			Decision::Table::Action::WithCode->new( # 1
							       text => '$this->nick( "dumb" )', 

							       cref => sub { $_[0]->nick( "dumb" ) } 
							      ),
			Decision::Table::Action::WithCode->new( # 2
							       text => '$this->nick( "geek" )', 
							       cref => sub { $_[0]->nick( "geek" ) } 
							      ),
			Decision::Table::Action::WithCode->new( # 3
							       text => '$this->nick( "unknown" )', 
							       cref => sub { $_[0]->nick( "unknown" ) } 
							      ),
		],

		rules =>
		[
			Decision::Table::Rule::Indexed->new( true => [ 0, 1, 2 ], actions => [ 0 ] ),
			Decision::Table::Rule::Indexed->new( true => [ 0, 2 ], actions => [ 1 ] ), # this will work
			Decision::Table::Rule::Indexed->new( true => [ 0, 1 ], actions => [ 2 ] ),
			Decision::Table::Rule::Indexed->new( true => [ 1, 2 ], actions => [ 3 ] ),
		],

		else => [ 3 ],
	);

    print STDERR "TO_CODE: ", $dtp->to_code();

ok(1);

use Data::Dump qw(dump);

use Class::Maker qw(:all);

	class 'Human',
	{
		public =>
		{
			string => [qw( hairs nick shorts)],

			integer => [qw( income )],
		},

		default =>
		{
		 income => 0,
		 shorts => 'clean',
		 nick => 'none'
		},
	};

	my $human = Human->new( hairs => 'green' );

        ok( $human->nick eq 'none' );

	println dump $dtp;

        println "HUMAN BEFORE decision ", dump $human;

	println "RUN: ", dump $dtp->run( $human );
	
        println "to_text:\n", $dtp->to_text;

        println "HUMAN AFTER decision ", dump $human;

        ok( $human->nick eq 'unknown' ); # due to else action

println dump [ $dtp->rules ];

        $human->income( 20*1000 );
    
	println "RUN: ", dump $dtp->run( $human );
	
        println "to_text:\n", $dtp->to_text;

        println "HUMAN AFTER decision ", dump $human;

        ok( $human->nick eq 'geek' );

ok(1);
