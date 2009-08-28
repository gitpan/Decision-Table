package Decision::Table::Diagnostic;

use 5.006; use strict; use warnings;

our $VERSION = '0.01_02';

our $DEBUG = 0;

use IO::Extended qw(:all);

Class::Maker::class
{
	isa => [qw(Decision::Table::Partial)],
	
	private => 
	{
		array => [qw( postrules )],
	}
};

1;
