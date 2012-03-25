use v5.10;
use strict;
use warnings FATAL => "all";
use utf8;
use version;
use Archive::Tar;
use ExtUtils::CChecker;
use File::Spec::Functions qw(catdir catfile);
use File::Path "remove_tree";
use IPC::Cmd qw(can_run run);
use Module::Build;
use Net::FTP;

my $builder = Module::Build->new(
	# Defaults inserted by DistZilla:
	##{ $plugin->get_prereqs ##}
	##{ $plugin->get_default(qw(dist_name license dist_abstract)) ##}
	##{ $plugin->get_default(qw(dist_author)) ##}
	dist_version_from => "lib/Alien/GMP.pm",
	share_dir => "share",
   );

$builder->have_c_compiler or die "C compiler not found";

my $check_gmp = <<'EOF';
#include <gmp.h>
int main(int argc, char *argv[]) { return __GNU_MP__ == 5 ? 0 : 1; }
EOF
my $cc = ExtUtils::CChecker->new;

my %paths = do {
	if ( !$ENV{COMPILE_ALIEN_GMP}
		 && $cc->try_compile_run( source => $check_gmp ) ) {
		say "GMP version >= 5.0.0 already installed; skipping compilation";

		# Find system include and lib directories:
		my @inc_paths = do {
			my $cc1 = qx(cc -print-prog-name=cc1);
			chomp $cc1;
			my (undef, undef, $res) = run(
				command => [$cc1, "-v"],
				timeout => 1 );
			$res->[0] =~ /^ (.+)$/mg };

		my ($inc_dir) = grep { -e catfile($_, "gmp.h") } @inc_paths;
		my ($lib_dir) = grep { -e catfile($_, "libgmp.so") } map {
				my $path = $_;
				$path =~ s/include/lib/;
				$path } @inc_paths;
		( inc_dir => $inc_dir, lib_dir => $lib_dir, extra_files => [] ) }
	else {
		can_run("libtool") or die "libtool not found";

		say "Downloading source archive from ftp.gmplib.org...";
		my $archive = "gmp-5.0.4.tar.bz2";
		my $ftp = Net::FTP->new("ftp.gmplib.org")
			or die "Unable to connect to ftp.gnu.org";
		$ftp->login or die "Unable to anonymously login to ftp.gnu.org";
		$ftp->binary;
		$ftp->get("/pub/gmp-5.0.4/$archive")
			or die "Failed to download $archive";
		$ftp->quit;

		say "Extracting...";
		Archive::Tar->new($archive)->extract;
		unlink $archive;

		# Compile/Install:
		say "Configuring GMP...";
		my $base_dir = $builder->base_dir;
		my $share_dir = catdir( $base_dir, "share" );
		my $gmp_dir = catdir( $base_dir, glob "gmp-*" );
		chdir $gmp_dir;
		run( command => [
			"./configure", "--prefix=$share_dir", "--enable-shared"] )
			or die "Failed to configure GMP";

		say "Compiling...";
		run( command => [qw(make -j9)]) or die "Failed to make GMP";

		say "Testing compilation...";
		run( command => [qw(make check -j9)] ) or die "GMP's make-check failed";

		say "Installing GMP...";
		run( command => [qw(make install)] ) or die "Failed to install GMP";

		# Gather include and lib directories:
		chdir $base_dir;
		remove_tree($gmp_dir);
		my @extra_files = (
			glob( catfile($builder->dist_dir, "include", "*") ),
			glob( catfile($builder->dist_dir, "lib", "*" ) ),
			glob( catfile($builder->dist_dir, "share", "*") ) );
		my $dest_sharedir = catdir( $builder->install_destination("lib"),
									"auto", "share", "dist", "Alien-GMP" );
		( inc_dir => catdir($dest_sharedir, "include"),
		  lib_dir => catdir($dest_sharedir, "lib"),
		  extra_files => \@extra_files ) } };

# Update manifest:
open my $MANIFEST, ">>", "MANIFEST";
print $MANIFEST @{ $paths{extra_files} };
close $MANIFEST;

# Write paths to GMP.pm:
do {
	open my $LIB, "<", "lib/Alien/GMP.pm";
	local $/;
	my $lib = <$LIB>;
	close $LIB;
	$lib =~ s/##/"$paths{inc_dir}"/;
	$lib =~ s/##/"$paths{lib_dir}"/;
	open $LIB, ">", "lib/Alien/GMP.pm";
	print $LIB $lib;
	close $LIB };

$builder->create_build_script;
