package Alien::GMP;

use v5.10;
use strict;
use warnings FATAL => "all";
use utf8;
use File::Spec::Functions qw(catdir);
use File::ShareDir "dist_dir";

# VERSION
# ABSTRACT: Build and install the GNU Multiple Precision library

my $dist_dir = File::ShareDir::dist_dir("Alien-GMP");

sub inc_dir {
	return catdir( $dist_dir, "include" ) }

sub lib_dir {
	return catdir( $dist_dir, "lib" ) }

1;
