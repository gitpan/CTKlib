package CTKx; # $Id: CTKx.pm 155 2013-10-15 09:50:12Z minus $
use strict;

=head1 NAME

CTKx - User extension CTK

=head1 VERSION

Version 1.00

=head1 REVISION

$Revision: 155 $

=head1 SYNOPSIS

    package main;

    use CTK;
    use CTKx;
    
    my $ctkx = CTKx->instance( c => new CTK );

    package MyApp;

    my $c = CTKx->instance->c;

=head1 ABSTRACT

CTKx - User extension CTK

=head1 DESCRIPTION

Extension for working with CTK as "Singleton Pattern"

=head1 HISTORY

=over 8

=item B<1.00 / 15.10.2013>

Init version

=back

See C<CHANGES> file for details

=head1 DEPENDENCIES

L<Class::Singleton>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<Class::Singleton>

=head1 DIAGNOSTICS

The usual warnings if it can't read or write the files involved.

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://www.serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use base qw/Class::Singleton/;
use vars qw($VERSION);
$VERSION = '1.00';

sub c { shift->{c} }

1;


