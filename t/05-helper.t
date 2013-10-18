#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id$
#
#########################################################################
use strict;
use warnings;

use Test::More tests => 2;
use CTK;
use CTKx;
BEGIN { use_ok('CTK::Helper') };

my $c = new CTK( syspaths => 1 );
my $ctkx = CTKx->instance(c => $c);
my $h = new CTK::Helper ( -t => 'regular' );
is($h->{class}, 'CTK::Helper::SkelRegular', 'Class for "regular" type');

1;

