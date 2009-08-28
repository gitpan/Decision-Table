use Test::More qw(no_plan);

use Decision::Table;

  my $dt = Decision::Table::Compact->new( 
    
      conditions =>
      [
       'drove too fast ?',            # pos 0
       'comsumed alcohol ?',          # pos 1
       'Police is making controls ?', # pos 2
      ],
      
      actions =>
      [
       'charged admonishment',         # 0
       'drivers license cancellation', # 1
       'nothing happened',             # 2
      ],

      rules =>
      [
       Decision::Table::Rule::Serial->new( true => [ 1, 0, 1 ], actions => [ 0 ] ),
       Decision::Table::Rule::Serial->new( true => [ 1, 1, 1 ], actions => [ 0, 1 ] ),
       Decision::Table::Rule::Serial->new( true => [ 0, 0, 0 ], actions => [ 2 ] ),
      ],
 );

 print $dt->to_text;

ok(1);

  my @rules = $dt->condition_find( true => [ 1, 1, 1 ] );

#    ln "CONDITION_FIND: dump = ", Data::Dump::dump [ @rules ]; 

    my $act = $rules[0]->{actions};

#   ln "Actins = ", Data::Dump::dump $act;

ok( $act->[0] == 0 && $act->[1] == 1 && scalar @$act == 2 );

