#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use.t 71 2012-12-28 22:11:58Z minus $
#
#########################################################################

use Test::More tests => 2;
BEGIN { use_ok('CTK'); };
is(CTK->VERSION,'1.06','Version checking');

