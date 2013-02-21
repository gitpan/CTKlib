#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 03-xsutil.t 119 2013-02-21 07:12:13Z minus $
#
#########################################################################
use strict;
use warnings;

use Test::More tests => 2;
BEGIN { use_ok('CTK::XS::Util') };

is(CTK::XS::Util::xsver(), $CTK::XS::Util::VERSION, 'XS Util testing');


