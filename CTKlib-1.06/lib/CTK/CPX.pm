package CTK::CPX; # $Id: CPX.pm 69 2012-12-28 19:26:44Z minus $
use Moose;
=head1 NAME

CTK::CPX - Converter between windows-1251 and your terminal encoding

=head1 VERSION

Version 1.01

=head1 REVISION

$Revision: 69 $

=head1 SYNOPSIS

    use CTK::CPX;
    tie *CP866, 'CTK::CPX'; # cp866 as default
    print CP866 "Privet","\n";

=head1 DESCRIPTION

Converter between windows-1251 and your terminal encoding.

Based on BeeCDR project

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 SEE ALSO

C<perl>, L<Moose>

=head1 DIAGNOSTICS

The usual warnings if it can't read or write the files involved.

=head1 COPYRIGHT

Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut
use namespace::autoclean;
extends qw/Tie::Handle/;
use Encode;
our $VERSION = '1.01';
sub TIEHANDLE { shift; my $incp = shift || 'cp866'; return bless [$incp], __PACKAGE__ }
sub PRINT {
    my $self = shift;
    print STDOUT Encode::encode(($self->[0] || 'cp866'),Encode::decode('Windows-1251',join("",@_)));
}
no Moose;
# Force constructor inlining
__PACKAGE__->meta->make_immutable(inline_constructor => 0); # replace_constructor => 1
1;
