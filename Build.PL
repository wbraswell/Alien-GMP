use v5.10;
use strict;
use warnings FATAL => "all";
use utf8;
use version;
use Archive::Tar;
use File::Spec;
use Module::Build;
use Net::FTP;
use PkgConfig;

my $builder = Module::Build->new(
	dist_name => "Alien-GMP",
	license => "LGPL_3_0",
	dist_abstract => "Build and install the GNU Multiple Precision library",
	dist_author => "Richard Simões <rsimoes AT cpan DOT org>",
	dist_version_from => "lib/Alien/GMP.pm",
	share_dir => { dist => "share" },
	# Prerequisites inserted by DistZilla:
	##{ $plugin->get_prereqs ##}
   );

my $res = PkgConfig->find("libgmp");
( $res->pkg_exists && version->new($res->pkg_version) > 5.000_004 )
	? do {
		say "gmp version >= 5.0.4 already installed; exiting...";
		exit }
	: do {
		my $errmsg = $res->errmsg;
		$errmsg and say $errmsg;
		say "Building and installing GMP...";

		# Download from FTP server:
		my $archive = "gmp-5.0.4.tar.bz2";
		my $ftp = Net::FTP->new("ftp.gmplib.org" )
			or die "Unable to connect to ftp.gnu.org";
		$ftp->login or die "Unable to anonymously login to ftp.gnu.org";
		$ftp->binary;
		$ftp->get("/pub/gmp-5.0.4/$archive")
			or die "Failed to download $archive";
		$ftp->quit;

		# Extract:
		Archive::Tar->new($archive)->extract;
		unlink $archive;

		# Compile/Install:
		my $base_dir = $builder->base_dir;
		my $share_dir = File::Spec->catdir( $base_dir, "share" );
		chdir glob "gmp-*";
		system("./configure", "--prefix=$share_dir", "--enable-shared") == 0
			or die "Failed to configure GMP";
		system("make") == 0 or die "Failed to make GMP";
		system("make", "install") == 0 or die "Failed to make GMP";
		chdir $base_dir;

		$builder->create_build_script };
