package CTK::CLI; # $Revision: 58 $
use Moose::Role; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::CLI - Command line interface

=head1 VERSION

1.00

$Id: CLI.pm 58 2012-12-26 10:45:15Z minus $

=head1 SYNOPSIS

    my $v = $c->cli_prompt('Your name:', 'anonymous');
    debug( "Your name: $v" );

    my $v = $c->cli_prompt3('Your name:');
    debug( "Your name: $v" );

    my $v = $c->cli_select('Your select:',[qw/foo bar baz/],'bar');
    debug( "Your select: $v" );
    
    my $v = $c->cli_select3('Your select:',[qw/foo bar baz/]);
    debug( "Your select: $v" );

=head1 DESCRIPTION

Command line interface. Prompt and select methods

=head1 TO DO

  * Use Term::ReadLine module. Sample:
    
    BEGIN { $ENV{TERM} = "dumb" if $^O eq "MSWin32" }
    use Term::ReadLine ();
    use Text::ParseWords qw(shellwords);

    my $term = new Term::ReadLine 'T01';
    my $prompt = "T> ";
    my $OUT = $term->OUT || \*STDOUT;
    while ( defined ($_ = $term->readline($prompt)) ) {
        last if /^(quit|exit)$/;
        my @w = shellwords($_);
        if (@w) {
        print join(" ",@w),"\n";
            $term->addhistory($_);
        }
    }
    print "\n";

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut


use vars qw/$VERSION/;
$VERSION = q/$Revision: 58 $/ =~ /(\d+\.?\d*)/ ? $1 : '1.00';

use CTK::Util qw(:API);
use ExtUtils::MakeMaker qw/prompt/;

sub cli_prompt {
    #  омандна€ строка, строка запроса
    # my $a = prompt('Input value a', '123');
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    my $msg = shift;
    my $def = shift;

    return prompt($msg,$def)
}
sub cli_prompt3 {
    # выполн€ет операцию cli_prompt 3 раза и возвращает результат
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    my $msg = shift;
    my $v = ''; 
    my $i = 0; 
    while ($i < 3) {$i++;
        $v = prompt($msg);
        last if defined($v) && $v ne '';
        CTK::say();
    }
    return $v;    
}
sub cli_select {
    # ¬озвращает выбранное значение
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    my $msg = shift;
    my $sel = shift || [];
    my $def = shift;

    my $v = _cli_select($sel);
    my $d = defined($def) ? $def : $v->[1];
    CTK::say($v->[1]) if $v->[0];
    $v = cli_prompt(defined($msg) ? $msg : '', $d);
    $v = _cli_select($sel, $v);
    
    return $v->[0] ? '' : $v->[1];
}
sub cli_select3 {
    # выполн€ет операцию cli_select 3 раза и возвращает результат
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    my $msg = shift;
    my $sel = shift || [];
    my $def = shift;
    
    unless ($sel && (!ref($sel) || ref($sel) eq 'ARRAY')) {
        carp("cli_select3: Call syntax error");
        $sel = [];
    }
    
    my $v = _cli_select($sel);
    my $d = defined($def) ? $def : $v->[1];
    my $i = 0;
    while ($i < 3) {$i++;
        CTK::say($v->[1]) if $v->[0];
        $v = cli_prompt(defined($msg) ? $msg : '', $d);
        $v = _cli_select($sel, $v);
        last unless ($v->[0]);
        CTK::say();
    }
    return $v->[0] ? '' : $v->[1];
}
sub _cli_select {
    # ¬озвращает либо значение, либо р€д значений, либо выбранное значение
    # ѕервый элемент - 0 - значение/выбранное значение
    #                  1 - ¬арианты (список в виде строк)
    my $v = shift;
    my $sel = shift;
    if (defined $v) {
        if (ref $v eq 'ARRAY') {
            if (defined($sel) && ($sel =~ /^\d+$/) && exists($v->[$sel-1])) {
                return [0,$v->[$sel-1]];
            } elsif (defined($sel) && grep {$_ eq $sel} @$v) {                
                return [0,$sel];
            } else {
                my $c=0;
                my @r=();
                foreach (@$v) {$c++; push @r, "$c) $_"}
                return [1,"Select one item:\n\t".join(";\n\t",@r)."\n"];
            }
        } else {
            return [0,defined $sel ? $sel : $v];
        }
    } else {
        return [0,''];
    }
}

#no Moose;
#__PACKAGE__->meta->make_immutable;
1;
__END__

    

