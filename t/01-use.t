#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 01-use.t 176 2013-12-03 11:48:49Z minus $
#
#########################################################################
use Test::More tests => 2;
BEGIN { use_ok('CTK'); };
is(CTK->VERSION,'1.16','Version checking');

