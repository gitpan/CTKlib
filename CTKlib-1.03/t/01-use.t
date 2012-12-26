#########################################################################
#
# Lepenkov Sergey (Serz Minus), <minus@mail333.com>
#
# Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use.t 52 2012-12-19 14:21:29Z minus $
#
#########################################################################

use Test::More tests => 2;
BEGIN { use_ok('CTK'); };
is(CTK->VERSION,'1.03','Version checking');

