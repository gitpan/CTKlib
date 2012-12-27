package CTK::File; # $Revision: 58 $
use Moose::Role; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::File - Files and direcries working

=head1 VERSION

1.00

$Id: File.pm 58 2012-12-26 10:45:15Z minus $

=head1 SYNOPSIS

    $c->fsplit(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (big files)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory (splitted files)
            -n      => 100, # Lines count
            -format => '[FILENAME]_%03d.[FILEEXT]', # Format
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );
    
    $c->fcopy(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (source files)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory
            -format => '[FILE].copy', # Format
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );
    
    $c->fmv(
            -in     => CTK::catfile($CTK::DATADIR,'in'),  # Source directory (source files)
            -out    => CTK::catfile($CTK::DATADIR,'out'), # Destination directory
            -format => '[FILE].copy', # Format
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );
    
    $c->frm(
            -in     => CTK::catfile($CTK::DATADIR,'in'), # Source directory (source files)
            -list   => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

=head1 DESCRIPTION

=head2 KEYS

=over 8

=item B<FILE>

Path and filename

=item B<FILENAME>

Filename only

=item B<FILEEXT>

File extension only

=item B<COUNT>

Current number of file in sequence (for fcopy and fmove methods)

Gor fsplit method please use perl mask %i

=item B<Time>

Current time value (time())

=back

=head2 NOTES

For copying paths: use File::Copy::Recursive qw(dircopy dirmove);

For TEMP dirs/files working: use File::Temp qw/tempfile tempdir/;

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

use CTK::Util qw(:API :FORMAT :ATOM);
use File::Copy;

sub fsplit {
    # Разделение файлов dirin и сохранение их в каталог dirproc по списку или маске с учетом 
    # кол-ва строк в одном файле и форматом вывода (sprintf)
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($dirin, $dirout, $listmsk, $limit, $format);
       ($dirin, $dirout, $listmsk, $limit, $format) = 
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['LIMIT','STRINGS','ROWS','MAX','ROWMAX','N','LIM'],
                ['FORMAT','FMT'],
            ],@args) if defined $args[0];
    
    $dirin    ||= ''; # Входная директория
    $dirout   ||= ''; # Директория обработки
    $listmsk  ||= ''; # Список имен файлов для процесса или маска
    $limit    ||=  0; # Лимит строк в файле
    $format   ||= ''; # Формат выводимого файла (sprintf) например: [FILENAME]_%03d.[FILEEXT]
    my $list;
    
    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirin,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirin,qr/$listmsk/);
    }


    # На этом этапе имеем линейный список фалов
    my $c = scalar(@$list) || 0;
    my $i = 0;
    #CTK::debug("Разбиение файлов каталога \"$dirin\" по ".correct_number($limit)." строк...");
    foreach my $fnin (@$list) {$i++;
        #CTK::debug("   Разбивается файл $i/$c $fnin...");
        my $filein = $dirin ? catfile($dirin,$fnin) : $fnin;
        open FIN, "<",$filein or _error("SPLIT ERROR: Can't open file $filein: $!") && next;
            my $fpart = 0; # Части
            my $fline = $limit; # строка, номер (условная!!!)
            open FOUT, ">-";
            while (<FIN>) { # chomp
                if ($fline >= $limit) {
                    # Достигнут лимит, Увеличиваем счетчик
                    $fline = 1;
                    $fpart++;
                    my $fformat  = fformat($format,$fnin);
                    my $fnproc   = sprintf($fformat,$fpart); # Выходной файл (имя)
                    my $fileproc = $dirout ? catfile($dirout,$fnproc) : $fnproc; #  Выходной файл
                    #CTK::debug("   - Сохраняется часть $fpart в файл $fnproc...");
                    close FOUT;
                    open FOUT, ">", $fileproc or _error("SPLIT ERROR: Can't open file $fileproc: $!") && next;
                } else {
                    # Читается факл
                    $fline++;
                }
                print FOUT; # print FOUT "\n";
            }
            close FOUT;
        close FIN or _error("SPLIT ERROR: Can't close file $filein: $!");
    }
    
    return 1;
}
sub fcopy {
    # копирование файлов с одной папки в другую по маске или списку
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($dirin, $dirout, $listmsk, $format);
       ($dirin, $dirout, $listmsk, $format) = 
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['FORMAT','FMT'],
            ],@args) if defined $args[0];

    $dirin    ||= '';     # Директория-источник
    $dirout   ||= '';     # Директория-приемник
    $listmsk  ||= '';     # Список имен файлов для копирования/переноса или маска
    $format   ||= '[FILE]'; # Формат выходного файла (sprintf). По умолчанию [FILE]
    my $list;

    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirin,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirin,qr/$listmsk/);
    }

    # На этом этапе имеем линейный список фалов
    my $c = scalar(@$list) || 0;
    my $i = 0;
    #CTK::debug("Копирование файлов каталога \"$dirin\" в \"$dirout\"...");
    foreach my $fn (@$list) {$i++;
        #CTK::debug("   Копируется файл $i/$c $fn...");
        my $dfd = dformat($format,{
                FILE  => $fn,
                COUNT => $i,
                TIME  => time()
            });
        copy(
                $dirin ? catfile($dirin,$fn) : $fn,
                $dirout ? catfile($dirout,$dfd) : $dfd,
            );
    }
    
    return 1;
}
sub fcp { fcopy(@_) }
sub fmove {
    # Перенос файлов с одной папки в другую по маске или списку
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($dirin, $dirout, $listmsk, $format);
       ($dirin, $dirout, $listmsk, $format) = 
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['FORMAT','FMT'],
            ],@args) if defined $args[0];

    $dirin    ||= '';     # Директория-источник
    $dirout   ||= '';     # Директория-приемник
    $listmsk  ||= '';     # Список имен файлов для копирования/переноса или маска
    $format   ||= '[FILE]'; # Формат выходного файла (sprintf). По умолчанию [FILE]
    my $list;

    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirin,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirin,qr/$listmsk/);
    }

    # На этом этапе имеем линейный список фалов  ::debug(join "; ", @$list);
    my $c = scalar(@$list) || 0;
    my $i = 0;
    #CTK::debug("Перенос файлов каталога \"$dirin\" в \"$dirout\"...");
    foreach my $fn (@$list) {$i++;
        #CTK::debug("   Переносится файл $i/$c $fn...");
        my $dfd = dformat($format,{
                FILE  => $fn,
                COUNT => $i,
                TIME  => time()
            });
        move(
                $dirin ? catfile($dirin,$fn) : $fn,
                $dirout ? catfile($dirout,$dfd) : $dfd,
            );
    }
    
    return 1;
}
sub fmv { fmove(@_) }
sub fdelete {
    # удаление файлов из папки по маске или списку
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($dirin, $listmsk);
       ($dirin, $listmsk) = 
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
            ],@args) if defined $args[0];
    
    $dirin    ||= '';     # Директория-источник
    $listmsk  ||= '';     # Список имен файлов для удаления или маска
    my $list;

    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirin,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirin,qr/$listmsk/);
    }

    # На этом этапе имеем линейный список фалов
    my $c = scalar(@$list) || 0;
    my $i = 0;
    #CTK::debug("Удаление файлов каталога \"$dirin\"...");
    foreach my $fn (@$list) {$i++;
        #CTK::debug("   удаляется файл $i/$c $fn...");
        unlink( $dirin ? catfile($dirin,$fn) : $fn);
    }
}
sub fdel { fdelete(@_) }
sub frm { fdelete(@_) }
sub _error {
    #CTK::debug(@_);
    carp(@_); # unless CTK::debugmode();
}

#no Moose;
#__PACKAGE__->meta->make_immutable;
1;
__END__
