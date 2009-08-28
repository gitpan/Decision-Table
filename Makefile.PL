use 5.008002;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Decision::Table',
    VERSION_FROM      => 'lib/Decision/Table.pm', # finds $VERSION
    PREREQ_PM         => {

	Class::Maker => 0,
	  
	  Data::Iter => 0,
	  
	  Math::Matrix => 0,
	  
	  Tie::RefHash => 0,
	  
	  
	  IO::Extended => 0,

	Perl::Tidy => 0,

	  Generator::Perl => 0,	  

      }, # e.g., Module::Name => 1.1
	      ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
	       (ABSTRACT_FROM  => 'lib/Decision/Table.pm', # retrieve abstract from module
		AUTHOR         => 'Murat Uenalan <muenalan@cpan.org>') : ()),
);
