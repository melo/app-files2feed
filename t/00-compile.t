#!perl

use strict;
use warnings;
use Test::More;
use Path::Class;
use File::Find;

my $lib = dir('lib')->absolute->resolve;
find({
  bydepth => 1,
  no_chdir => 1,
  wanted => sub {
    my $m = $_;
    return unless $m =~ s/[.]pm$//;

    $m =~ s{^.*/lib/}{};
    $m =~ s{/}{::}g;
    use_ok($m) || BAIL_OUT("***** PROBLEMS LOADING FILE '$m'");
  },
}, $lib);

done_testing();
