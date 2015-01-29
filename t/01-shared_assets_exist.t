#!/usr/bin/env perl

use Test::More tests => 4;
use strict;
use warnings FATAL => "all";
use Alien::GMP;
use File::Spec::Functions qw(catdir catfile);

my $inc_dir = Alien::GMP->install_type() eq 'share'
	# If GMP was compiled, look for inc_dir in build directory instead of
	# eventual install location:
	? Alien::GMP->dist_dir()
	: ( Alien::GMP->cflags() =~ /-I([^\s]+)/ )[0];
my $gmp_h = catfile($inc_dir, "gmp.h");
ok -d $inc_dir, "GMP include directory exists";
ok -f $gmp_h, "GMP header file exists";


my @lib_dirs = ( Alien::GMP->libs() =~ /-L([^\s]+)/g );

my $libgmp_lib_name = 'libgmp.so';
my @libgmp_dirs = grep { -f catfile( $_ , $libgmp_lib_name ) } @lib_dirs;
my $libgmp_dir = $libgmp_dirs[0];

my $libgmp_so = catfile( $libgmp_dir, $libgmp_lib_name );
ok -d $libgmp_dir, "GMP lib directory exists";
ok -f $libgmp_so, "GMP shared object exists";
