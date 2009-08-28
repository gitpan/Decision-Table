use Test::More qw(no_plan);

use strict;

use Decision::Table;
use Decision::Table::Weighted;

ok(1);

use Data::Dumper;
use Class::Maker qw(:all);

ok(1);

    my $wheather_context = Decision::Table::Context->new( text => 'Summer' );
    
    my $dtp;
    
	##
	## Weighted Decision::Table::Conditions for Categorizing Decision Tables
	##
	##    highest weight (i.e. 0-100 => 100) means evidentiary 
	
		# Localization (Whereami ?)
    
    $Decision::Table::Weighted::DEBUG = 1;
    
	$dtp = Decision::Table::Weighted->new(
	
		conditions =>
		[
			Decision::Table::Condition::Weighted->new( 
								  text => 'Inhabitats are small', 
								  weight => 30, 
								  cref => sub { $_[0]->size eq 'small' } 
								 ),
			Decision::Table::Condition::Weighted->new( 
								  text => 'Inhabitats are large', 
								  weight => 30, 
								  cref => sub { $_[0]->size eq 'large' } 
								 ),
			Decision::Table::Condition::Weighted->new( 
								  text => 'Inhabitats have dark skin', 
								  weight => 90, 
								  cref => sub { $_[0]->skin eq 'dark' } 
								 ),
			Decision::Table::Condition::Weighted->new( 
								  text => 'Whether is hot', 
								  weight => 10, 
								  cref => sub { $_[1]->temperature eq 'hot' } 
								 ),
			Decision::Table::Condition::Weighted->new( 
								  text => 'It is rainy', 
								  weight => 10, 
								  cref => sub { $_[1]->humidity eq 'rainy' } 
								 ),
			Decision::Table::Condition::Weighted->new( 
								  text => 'I have seen a kangoroo', 
								  weight => 99, 
								  cref => sub { exists $_[1]->animals->{'kangoroo'} } 
								 ),
			Decision::Table::Condition::Weighted->new( 
								  text => 'I have seen a desert', 
								  weight => 80, 
								  cref => sub { $_[1]->landscape eq '' } 
								 ),
		],

		actions =>
		[
			Decision::Table::Action->new( id => 'eu', text => 'Europe' ),
			Decision::Table::Action->new( id => 'as', text => 'Asia' ),
			Decision::Table::Action->new( id => 'am', text => 'Amerika' ),
			Decision::Table::Action->new( id => 'au', text => 'Australia' ),
			Decision::Table::Action->new( id => 'af', text => 'Afrika' ),
		],

		rules =>
		[
			Decision::Table::Rule->new( true => [ 0, 1, 2 ], actions => [ 1 ] ),
			Decision::Table::Rule->new( true => [ 1, 2 ],    actions => [ 2 ] ), 
			Decision::Table::Rule->new( true => [ 0, 2, 5 ], actions => [ 3 ] ),
			Decision::Table::Rule->new( true => [ 0, 3 ],    actions => [ 4 ] ),
		],

		else => [ 3 ],
	);

    print STDERR "TO_CODE: ", $dtp->to_code();

	class 'Inhabitant',
	{
		public =>
		{
			string => [qw( size skin )],
		},
	};

	class 'Enviroment',
	{
		public =>
		{
			string => [qw( humidity temperature landscape )],

			hash => [qw( animals )],
		},
	};

	my $i = Inhabitant->new( size => 'small', skin => 'dark' );

	my $e = Enviroment->new( humidity => 'rainy', temperature => 'cold', animals => { kangoroo => 1 }, landscape => 'desert' );
	
	IO::Extended::println Data::Dump::dump [ $dtp->decide( $i, $e ) ];
    
ok(2);

__END__
