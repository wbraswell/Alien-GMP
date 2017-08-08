use Test2::V0;
use Test::Alien;
use Alien::GMP;

alien_ok 'Alien::GMP';

diag '';
diag '';
diag '';

diag sprintf("%20s = %s", $_, Alien::GMP->$_) for qw( version cflags cflags_static libs libs_static install_type );

diag '';
diag '';


xs_ok do { local $/; <DATA> }, with_subtest {
  my($mod) = @_;
  ok $mod->get_version;
  note "version = ", $mod->get_version;
};

done_testing;

__DATA__
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <gmp.h>

MODULE = TA_MODULE PACKAGE = TA_MODULE

const char *
get_version(klass)
    const char *klass
  CODE:
    RETVAL = gmp_version;
  OUTPUT:
    RETVAL
