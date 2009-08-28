# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test;
BEGIN { plan tests => 1 };
use Decision::Table;
ok(1); # If we made it this far, we're ok.

#########################
# Insert your test code below, the Test module is use()ed here so read
# its man page ( perldoc Test ) for help writing this test script.

# 	The optimum syntax-tree would be ?

# 	 if( [ X, X, 1 ] )
#	 {
#		here is [X, X, 1];
#
#		if( [ X, 1, X ] )
#		{
	#		here is [X, 1, 1];

	#		if( [ 1, X, X ] )
	#		{
	#			here is [1, 1, 1];
	#		}
	#		else
	#		{
	#
	#		}
#
#		}
#	}

	#print Dumper $dtp;
	
	# Heuristic Decision Tables
	
	# Context Decision Table

__END__

=head1 Contexts

Mensch
	Author
		Buch
		Zeitschrift
		Web
	
comp
comp.lang
comp.lang.perl
comp.lang.perl.mod
comp.lang.perl.misc
comp.lang.ruby
comp.lang.php
	
=cut

