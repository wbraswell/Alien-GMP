use Test2::V0;
use Test::Alien;
use Alien::GMP;

skip_all 'test requires a dynamic build' unless Alien::GMP->dynamic_libs;

alien_ok 'Alien::GMP';

diag '';
diag '';
diag '';

diag(sprintf("%20s = %s", 'dynamic_libs[]', $_)) for Alien::GMP->dynamic_libs;

diag '';
diag '';

ffi_ok { symbols => [ '__gmpz_init_set_str', '__gmpz_mul' ] }, with_subtest {
  my($ffi) = @_;
  eval q{ require FFI::Platypus::Memory };
  my $a = FFI::Platypus::Memory::malloc(24);
  my $b = FFI::Platypus::Memory::malloc(24);

  my $init_set_str = $ffi->function(__gmpz_init_set_str => ['opaque', 'string', 'int'] => 'int');
  my $ret1 = $init_set_str->($a, '39679054966380032223487239670184', 10);
  my $ret2 = $init_set_str->($b, '85186439059104575627262464195387', 10);
  
  my $z_clear = $ffi->function(__gmpz_clear => ['opaque'] => 'void');
  $z_clear->($a);
  $z_clear->($b);
  
  note "ret1 = $ret1";
  note "ret2 = $ret2";
  ok 1, 'did not SEGV';
};

done_testing;
