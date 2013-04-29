
use strict;
use warnings;



use ExtUtils::MakeMaker 6.30;



my %WriteMakefileArgs = (
  "ABSTRACT" => "Layered configuration, because configs are like ogres",
  "AUTHOR" => "Dave Sherohman <dsheroh\@cpan.org>",
  "BUILD_REQUIRES" => {
    "FindBin" => 0,
    "Test::Exception" => 0,
    "Test::More" => 0
  },
  "CONFIGURE_REQUIRES" => {
    "ExtUtils::MakeMaker" => "6.30"
  },
  "DISTNAME" => "Config-Onion",
  "EXE_FILES" => [],
  "LICENSE" => "perl",
  "NAME" => "Config::Onion",
  "PREREQ_PM" => {
    "Config::Any" => 0,
    "Exporter" => 0,
    "Hash::Merge::Simple" => 0,
    "Moo" => 0,
    "base" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "VERSION" => "1.000",
  "test" => {
    "TESTS" => "t/*.t"
  }
);


unless ( eval { ExtUtils::MakeMaker->VERSION(6.56) } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
      $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION(6.52) };

WriteMakefile(%WriteMakefileArgs);



