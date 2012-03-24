#!/usr/bin/env perl

use Test::More tests => 2;
use strict;
use warnings FATAL => "all";
use Alien::GMP;

ok -e Alien::GMP::inc_dir, "include directory exists";
ok -e Alien::GMP::lib_dir, "lib directory exists";
