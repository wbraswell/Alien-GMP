use strict;
use warnings FATAL => "all";
use utf8;
use version;
use Archive::Tar;
use Cwd qw(realpath);
use ExtUtils::CChecker;
use File::Spec::Functions qw(catdir catfile);
use File::Path "remove_tree";
use IPC::Cmd qw(can_run run);
use Module::Build;
use Net::FTP;
use Alien::Autotools qw(autoconf_dir automake_dir libtool_dir);
use File::Path qw(make_path);

# Prevent warnings about missing share directory:
make_path("share");

# Include autotools bin directories for compilation:
$ENV{PATH} = autoconf_dir() . ":" . automake_dir() . ":" . libtool_dir()
			 . ":$ENV{PATH}";

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
		print "GMP version >= 5.0.0 already installed; skipping compilation\n";

		# Find system include and lib directories:
		my @inc_paths = map {
			s/\n.*$//;
			s/^.+ =?//;
			-d $_ ? realpath($_) : () } split /:/, qx(cc -print-search-dirs);
		my ($inc_dir) = grep { -f catfile($_, "gmp.h") } map {
			my $path = $_;
			$path =~ s/lib/include/;
			$path } @inc_paths;
		my ($lib_dir) = grep { -f catfile($_, "libgmp.so") } @inc_paths;
		( inc_dir => $inc_dir, lib_dir => $lib_dir, extra_files => [] ) }
	else {
		can_run("libtool") or die "libtool not found";

		print "Downloading GMP source archive from ftp.gnu.org...\n";
		my $archive = "gmp-5.0.4.tar.bz2";
		my $ftp = Net::FTP->new("ftp.gnu.org")
			or die "Unable to connect to ftp.gnu.org";
		$ftp->login or die "Unable to anonymously login to ftp.gnu.org";
		$ftp->binary;
		$ftp->get("/gnu/gmp/$archive") or die "Failed to download $archive";
		$ftp->quit;

		print "Extracting...\n";
		Archive::Tar->new($archive)->extract;
		unlink $archive;

		# Compile/Install:
		print "Configuring...\n";
		my $base_dir = $builder->base_dir;
		my $share_dir = catdir( $base_dir, "share" );
		my $gmp_dir = catdir( $base_dir, glob "gmp-*" );
		chdir $gmp_dir;
		run( command => [
			"./configure", "--prefix=$share_dir", "--enable-shared"] )
			or die "Failed to configure GMP";

		print "Compiling...\n";
		run( command => [qw(make -j9)]) or die "Failed to make GMP";

		print "Installing...\n";
		run( command => [qw(make install)] ) or die "Failed to install GMP";

		# Gather include and lib directories:
		chdir $base_dir;
		remove_tree($gmp_dir);
		my @extra_files = ( glob( catfile qw(share include *) ),
							glob( catfile qw(share lib *) ),
							glob( catfile qw(share share info *) ) );
		my $dest_sharedir = catdir( $builder->install_destination("lib"),
									"auto", "share", "dist", "Alien-GMP" );
		( inc_dir => catdir($dest_sharedir, "include"),
		  lib_dir => catdir($dest_sharedir, "lib"),
		  extra_files => \@extra_files ) } };

# Update manifest:
open my $MANIFEST, ">>", "MANIFEST";
print $MANIFEST join "\n", @{ $paths{extra_files} };
close $MANIFEST;

# Write paths to GMP.pm:
do {
	my $pm_file = catfile qw(lib Alien GMP.pm);
	open my $LIB, "<", $pm_file;
	local $/;
	my $lib = <$LIB>;
	close $LIB;
	$lib =~ s/##/$paths{inc_dir}/;
	$lib =~ s/##/$paths{lib_dir}/;
	open $LIB, ">", $pm_file;
	print $LIB $lib;
	close $LIB };

$builder->create_build_script;
