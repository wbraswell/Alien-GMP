package Alien::GMP;

use strict;
use warnings;

use parent 'Alien::Base';

# VERSION
# ABSTRACT: Alien package for the GNU Multiple Precision library.

sub Inline {
	return unless $_[-1] eq 'C'; # Inline's error message is good
	my $self = __PACKAGE__->new;
	+{
		LIBS => $self->libs,
		INC => $self->cflags,
		# NOTE: it may be necessary to also include
		# <stdio.h>, <stdarg.h>, or <obstack.h> before gmp.h for
		# certain functionality
		AUTO_INCLUDE => '#include "gmp.h"',
	};
}

1;
1;
