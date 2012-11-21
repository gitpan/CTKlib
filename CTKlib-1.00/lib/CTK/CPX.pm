=head1 NAME

CTK::CPX

=head1 VERSION

$Id: CPX.pm 29 2012-11-20 14:50:39Z minus $

Based on BeeCDR

=head1 SYNOPSIS

    use CTK::CPX;
    tie *CP866, 'CTK::CPX'; # cp866 as default
    print CP866 "Привет","\n";

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru>, E<lt>minus@mail333.comE<gt>.

=head1 SEE ALSO

C<perl>, C<Moose>

=head1 DIAGNOSTICS

The usual warnings if it can't read or write the files involved.

=head1 COPYRIGHT

    This program is distributed under the GNU GPL v3.

    Copyright (C) 1998-2010 D&D Corporation. All Rights Reserved

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
    GNU General Public License for more details.

=cut
package CTK::CPX;
use Moose;
use namespace::autoclean;
extends qw/Tie::Handle/;
use Encode;
our $VERSION = '1.00';
sub TIEHANDLE { shift; my $incp = shift || 'cp866'; return bless [$incp], __PACKAGE__ }
sub PRINT {
    my $self = shift;
    print STDOUT Encode::encode(($self->[0] || 'cp866'),Encode::decode('Windows-1251',join("",@_)));
}
no Moose;
# Force constructor inlining
__PACKAGE__->meta->make_immutable(inline_constructor => 0); # replace_constructor => 1
1;
