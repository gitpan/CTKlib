package CTK::Util; # $Revision: 58 $
use strict;
# use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::Util - Utilities

=head1 VERSION

1.00

$Id: Util.pm 58 2012-12-26 10:45:15Z minus $

=head1 SYNOPSIS

    my $sent = send_mail(
        -to       => 'to@example.com',
        -cc       => 'cc@example.com',     ### OPTIONAL
        -from     => 'from@example.com',
        -subject  => 'my subject',
        -message  => 'my message',
        -type     => 'text/plain',
        -sendmail => '/usr/sbin/sendmail', ### OPTIONAL
        -charset  => 'windows-1251',
        -flags    => '-t',                 ### OPTIONAL
        -smtp     => '192.168.1.1',        ### OPTIONAL
        -authuser => '',                   ### OPTIONAL
        -authpass => '',                   ### OPTIONAL
        -attach   => [                     ### OPTIONAL
            { 
                Type=>'text/plain', 
                Data=>'document 1 content', 
                Filename=>'doc1.txt', 
                Disposition=>'attachment',
            },
            {
                Type=>'text/plain', 
                Data=>'document 2 content', 
                Filename=>'doc2.txt', 
                Disposition=>'attachment',
            },
            {
                Type=>'text/html', 
                Data=>'blah-blah-blah', 
                Filename=>'response.htm', 
                Disposition=>'attachment',
            },
            {
                Type=>'image/gif', 
                Path=>'aaa000123.gif',
                Filename=>'logo.gif', 
                Disposition=>'attachment',
            },
            ### ... ###
          ],
    );
    debug($sent ? 'mail has been sent :)' : 'mail was not sent :(');
    
    # General API
    my @args = @_;
    my ($content, $maxcnt, $timeout, $timedie, $base, $login, $password, $host, $table_tmp);
    ($content, $maxcnt, $timeout, $timedie, $base, $login, $password, $host, $table_tmp) =
    read_attributes([
        ['DATA','CONTENT','USERDATA'],
        ['COUNT','MAXCOUNT','MAXCNT'],
        ['TIMEOUT','FORBIDDEN','INTERVAL'],
        ['TIMEDIE','TIME'],
        ['BD','DB','BASE','DATABASE'],
        ['LOGIN','USER'],
        ['PASSWORD','PASS'],
        ['HOST','HOSTNAME','ADDRESS','ADDR'],
        ['TABLE','TABLENAME','NAME','SESSION','SESSIONNAME']
    ],@args) if defined $args[0];


=head1 DESCRIPTION

no public subroutines

=head1 SEE ALSO

L<MIME::Lite>, L<CGI::Util>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use constant {
    DEBUG     => 1, # 0 - off, 1 - on, 2 - all (+ http headers and other)
};

use vars qw/$VERSION/;
$VERSION = q/$Revision: 58 $/ =~ /(\d+\.?\d*)/ ? $1 : '1.00';

use Time::Local;
use File::Spec::Functions qw(catfile rootdir tmpdir updir);
use MIME::Base64;
use MIME::Lite;
use Net::FTP;
use File::Path; # mkpath / rmtree
use IPC::Open3;

use Carp qw/carp croak cluck confess/;
# carp    -- просто пишем
# croak   -- просто пишем и убиваем
# cluck   -- пишем но с подробностями
# confess -- пишем с подробностями и убиваем

use base qw /Exporter/;
our @EXPORT = qw(
        to_utf8 to_windows1251 CP1251toUTF8 UTF8toCP1251 to_base64 
        unescape slash tag tag_create cdata dformat fformat splitformat
        correct_number correct_dig
        translate variant_stf randomize
        
        current_date current_date_time localtime2date localtime2date_time correct_date date2localtime
        datetime2localtime visokos date2dig dig2date date_time2dig dig2date_time basetime
        
        load_file save_file file_load file_save fsave fload bsave bload touch
        
        preparedir
        sendmail send_mail
        scandirs scanfiles
        ftp ftptest ftpgetlist getlist getdirlist 
        procexec procexe proccommand proccmd procrun exe com execute
        
        catfile rootdir tmpdir updir
        carp croak cluck confess
        
        read_attributes
    );
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = (
        ALL     => [@EXPORT],
        DEFAULT => [@EXPORT],
        BASE    => [qw(
                to_utf8 to_windows1251 CP1251toUTF8 UTF8toCP1251 to_base64 
                unescape slash tag tag_create cdata dformat fformat splitformat
                correct_number correct_dig
                translate variant_stf randomize
                load_file save_file file_load file_save fsave fload bsave bload touch
                sendmail send_mail
                scandirs scanfiles
                read_attributes
            )],
        FORMAT  => [qw(
                to_utf8 to_windows1251 CP1251toUTF8 UTF8toCP1251 to_base64 
                unescape slash tag tag_create cdata dformat fformat splitformat
                correct_number correct_dig
                translate variant_stf randomize
            )],
        DATE    => [qw(
                current_date current_date_time localtime2date localtime2date_time correct_date date2localtime
                datetime2localtime visokos date2dig dig2date date_time2dig dig2date_time basetime
            )],
        FILE    => [qw(load_file save_file file_load file_save fsave fload bsave bload touch)],
        UTIL    => [qw(
                preparedir
                sendmail send_mail
                scandirs scanfiles
                ftp ftptest ftpgetlist getlist getdirlist 
                procexec procexe proccommand proccmd procrun exe com execute
                catfile rootdir tmpdir updir
                carp croak cluck confess
                read_attributes
            )],
        ATOM   => [qw(
                scandirs scanfiles
                ftp ftptest ftpgetlist getlist getdirlist 
                procexec procexe proccommand proccmd procrun exe com execute
            )],
        API    => [qw(
                catfile rootdir tmpdir updir
                carp croak cluck confess
                read_attributes
            )],
    );

sub send_mail {
    # Version 3.01 (with UTF-8 as default character set and attachment support)    
    #
    # Отправка письма посредством модуля MIME::Lite в кодировке UTF-8
    # Возвращает статус отправки. 1 - удача, 0 - неудача. Данные записались в лог
    #
    
    my @args = @_;
    my ($to, $cc, $from, $subject, $message, $type, 
        $sendmail, $charset, $mailer_flags, $smtp, $smtpuser, $smtppass,$att);
    
    # Приём данных
    ($to, $cc, $from, $subject, $message, $type, 
     $sendmail, $charset, $mailer_flags, $smtp, $smtpuser, $smtppass, $att) =
    read_attributes([
        ['TO','KOMU','ADDRESS'],
        ['COPY','CC'],
        ['FROM','OT','OTKOGO','OT_KOGO'],
        ['SUBJECT','SUBJ','SBJ','TEMA','DESCRIPTION'],
        ['MESSAGE','CONTENT','TEXT','MAIL','DATA'],
        ['TYPE','CONTENT-TYPE','CONTENT_TYPE'],
        ['PROGRAM','SENDMAIL','PRG'],
        ['CHARSET','CHARACTER_SET'],
        ['FLAG','FLAGS','MAILERFLAGS','MAILER_FLAGS','SENDMAILFLAGS','SENDMAIL_FLAGS'],
        ['SMTP','MAILSERVER','SERVER','HOST'],
        ['SMTPLOGIN','AUTHLOGIN','LOGIN','SMTPUSER','AUTHUSER','USER'],
        ['SMTPPASSWORD','AUTHPASSWORD','PASSWORD','SMTPPASS','AUTHPASS','PASS'],
        ['ATTACH','ATTACHE','ATT'],
    ],@args) if defined $args[0];

    # По умолчанию берутся пустые данные, в дальнейшем -- данные конфигурации
    $to           ||= ''; 
    $cc           ||= '';
    $from         ||= '';
    $subject      ||= '';
    $message      ||= '';
    $type         ||= "text/plain";
    $sendmail     ||= "/usr/lib/sendmail";
    $sendmail       = "/usr/sbin/sendmail" if !-e $sendmail;
    $sendmail       = "" if (-e $sendmail) && (-l $sendmail);
    $charset      ||= "Windows-1251";
    $mailer_flags ||= "-t";
    $smtp         ||= ''; 
    $smtpuser     ||= ''; 
    $smtppass     ||= ''; 
    $att          ||= '';

    # Преобразование полей темы и данных в выбранную кодировку
    if ($charset !~ /utf\-?8/i) {
        $subject = to_utf8($subject,$charset);
        $message = to_utf8($message,$charset);
    }
    
    # Формирую объект
    my $msg = MIME::Lite->new( 
        From     => $from,
        To       => $to,
        Cc       => $cc,
        Subject  => to_base64($subject),
	    Type     => $type,
        Encoding => 'base64',
        Data     => Encode::encode('UTF-8',$message)
    );
    # Устанавливаем кодовую таблицу
    $msg->attr('content-type.charset' => 'UTF-8');
    $msg->attr('Content-Transfer-Encoding' => 'base64');
    
    # Аттач (если он есть)
    if ($att) {
        if (ref($att) =~ /HASH/i) {
            $msg->attach(%$att);
        } elsif  (ref($att) =~ /ARRAY/i) {
            foreach (@$att) {
                if (ref($_) =~ /HASH/i) {
                    $msg->attach(%$_);
                } else {
                    _debug("невозможно присоединить множественные данные или файл к отправляемому письму");
                }
            }
        } else {
            _debug("невозможно присоединить данные или файл к отправляемому письму");
        }
    }

    # Отправка письма
    my $sendstat;
    if ($sendmail && -e $sendmail) {
        # sendmail указан и он существует
        $sendstat = $msg->send(sendmail => "$sendmail $mailer_flags");
        _debug("[SENDMAIL: program sendmail not found! \"$sendmail $mailer_flags\"] $!") unless $sendstat;
                   
    } else {
        # Попытка использовать SMTP сервер
        my %auth;
        %auth = (AuthUser=>$smtpuser, AuthPass=>$smtppass) if $smtpuser;
        eval { $sendstat = $smtp ? $msg->send('smtp',$smtp,%auth) : $msg->send(); };
        _debug("[SENDMAIL: bad send message ($smtp)!] $@") if $@;
        _debug("[SENDMAIL: bad method send($smtp)!] $!") unless $sendstat; 
    }
    #_debug("[SENDMAIL: The mail has been successfully sent to $to ",::tms(),"]") if $sendstat;

    return $sendstat ? 1 : 0;    
}
sub sendmail { send_mail(@_) }
sub to_utf8 {
    # Конвертирование строки в UTF-8 из указанной кодировки
    # to_utf8( $string, $charset ) # charset is 'Windows-1251' as default

    my $ss = shift || return ''; # Сообщение
    my $ch = shift || 'Windows-1251'; # Перекодировка
    return Encode::decode($ch,$ss)
}
sub to_windows1251 {
    my $ss = shift || return ''; # Сообщение
    my $ch = shift || 'Windows-1251'; # Перекодировка
    return Encode::encode($ch,$ss)
}
sub CP1251toUTF8 {to_utf8(@_)};
sub UTF8toCP1251 {to_windows1251(@_)};
sub to_base64 {
    # Конвертирование строки UTF-8  в base64
    # to_base64( $utf8_string )

    my $ss = shift || ''; # Сообщение
    return '=?UTF-8?B?'.MIME::Base64::encode(Encode::encode('UTF-8',$ss),'').'?=';
}

#
# Форматные функции
# 
sub slash {
    #
    # Процедура удаляет системные данные из строки заменяя их 
    #
    my $data_staring = shift || '';

    $data_staring =~ s/\\/\\\\/g;
    $data_staring =~ s/'/\\'/g;

    return $data_staring;
}
sub tag {
    #
    # Процедура удаляет системные данные из строки заменяя их 
    #
    my $data_staring = shift || '';

    $data_staring =~ s/</&lt;/g;
    $data_staring =~ s/>/&gt;/g;
    $data_staring =~ s/\"/&quot;/g;
    $data_staring =~ s/\'/&#39;/g;

    return $data_staring;    
}
sub tag_create {
    #
    # Процедура восстанавливает теги
    #
    my $data_staring = shift || '';

    $data_staring =~ s/\&#39\;/\'/g;
    $data_staring =~ s/\&lt\;/\</g;
    $data_staring =~ s/\&gt\;/\>/g;
    $data_staring =~ s/\&quot\;/\"/g;
 
    return $data_staring;    
}
sub cdata {
    my $s = shift;
    # Константы
    my $ss  = '<![CDATA[';
    my $sf  = ']]>';
    if (defined $s) {
        return to_utf8($ss).$s.to_utf8($sf);
    }
    return '';
}
sub unescape($) { 
    # Обратное преобразование URL разделителей типа &amp; => &
    # unescape( $string )
    
    my $c = shift || return ''; 
    $c=~s/&amp;/&/g; 
    return $c; 
}
sub dformat { # маска, данные для замены в виде ссылки на хэш
    # Заменяет во входном шаблоне внутренние параметры на подставляемые
    my $fmt = shift || ''; # Формат для замены
    my $fd  = shift || {}; # Данные для замены
    $fmt =~ s/\[(.+?)\]/(defined $fd->{uc($1)} ? $fd->{uc($1)} : '')/eg;
    return $fmt;
}
sub fformat { # маска, имя файла
    # Заменяет во входном шаблоне внутренние параметры на разделенные
    # [FILENAME] -- Только имя файла
    # [FILEEXT]  -- Только расширение файла
    # [FILE]     -- Все имя файла и расширрение вместе
    my $fmt = shift || ''; # Формат. Например такй: [FILENAME]-blah-blah-blah.[FILEEXT]
    my $fin = shift || ''; # Имя файла которое будем всталять "по формату", например void.txt
    
    my ($fn,$fe) = ($fin =~ /^(.+)\.([0-9a-zA-Z]+)$/) ? ($1,$2) : ($fin,'');
    $fmt =~ s/\[FILENAME\]/$fn/ig;
    $fmt =~ s/\[NAME\]/$fn/ig;
    $fmt =~ s/\[FILEEXT\]/$fe/ig;
    $fmt =~ s/\[EXT\]/$fe/ig;
    $fmt =~ s/\[FILE\]/$fin/ig;
    return $fmt; # void-blah-blah-blah.txt
}
sub splitformat { fformat(@_) }
#
# Корректировочные функции
# 
sub correct_number {
    # Расстановка разрядов в числе
    my $var = shift || 0;
    my $sep = shift || "`";
    1 while $var=~s/(\d)(\d\d\d)(?!\d)/$1$sep$2/;
    return $var;
}
sub correct_dig {
    # Процедура корректировки значения на факт числа. Если значение состоит НЕ из цифр то возвращается 0
    my $dig=shift || '';
    if ($dig =~/^(\d{1,11})$/) {
        return $1;    
    }
    return 0;
}

#
# Конверторы дат и времени
#
sub current_date {
    my @dt=localtime(time);
    my $cdt= (($dt[3]>9)?$dt[3]:'0'.$dt[3]).'.'.(($dt[4]+1>9)?$dt[4]+1:'0'.($dt[4]+1)).'.'.($dt[5]+1900);
    return $cdt;
}
sub current_date_time {
    my @dt=localtime(time);
    my $cdt= (($dt[3]>9)?$dt[3]:'0'.$dt[3]).'.'.(($dt[4]+1>9)?$dt[4]+1:'0'.($dt[4]+1)).'.'.($dt[5]+1900)." ".(($dt[2]>9)?$dt[2]:'0'.$dt[2]).":".(($dt[1]>9)?$dt[1]:'0'.$dt[1]).':'.(($dt[0]>9)?$dt[0]:'0'.$dt[0]);
    return $cdt;
}
sub localtime2date {
    # Преобразование времени в дату формата 02.12.2010
    # localtime2date ( time() ) # => 02.12.2010

    my $dandt=shift || time;
    my @dt=localtime($dandt);
    #my $cdt= (($dt[3]>9)?$dt[3]:'0'.$dt[3]).'.'.(($dt[4]+1>9)?$dt[4]+1:'0'.($dt[4]+1)).'.'.($dt[5]+1900);
    #return $cdt;
    return sprintf (
        "%02d.%02d.%04d",
        $dt[3], # День
        $dt[4]+1, # Месяц
        $dt[5]+1900 # Год
    );
}
sub localtime2date_time {
    my $dandt=shift || time;
    my @dt=localtime($dandt);
    #my $cdt= (($dt[3]>9)?$dt[3]:'0'.$dt[3]).'.'.(($dt[4]+1>9)?$dt[4]+1:'0'.($dt[4]+1)).'.'.($dt[5]+1900)." ".(($dt[2]>9)?$dt[2]:'0'.$dt[2]).":".(($dt[1]>9)?$dt[1]:'0'.$dt[1]).':'.(($dt[0]>9)?$dt[0]:'0'.$dt[0]);
    #return $cdt;
    return sprintf (
        "%02d.%02d.%04d %02d:%02d:%02d",
        $dt[3], # День
        $dt[4]+1, # Месяц
        $dt[5]+1900, # Год
        $dt[2], # Час
        $dt[1], # Мин
        $dt[0]  # Сек
    );

}
sub correct_date {
    #
    # Приведение даты в корректный правильный формат dd.mm.yyyy
    #
    my $date=shift;

    if ($date  =~/^\s*(\d{1,2})\D+(\d{1,2})\D+(\d{4})\s*$/) {
        my $dd = (($1<10)?('0'.($1/1)):$1);
        my $mm = (($2<10)?('0'.($2/1)):$2);
        my $yyyy=$3;
        if (($dd > 31) or ($dd <= 0)) {return ''};
        if (($mm > 12) or ($mm <= 0)) {return ''};
        my @aday = (31,28+visokos($yyyy),31,30,31,30,31,31,30,31,30,31);
        if ($dd > $aday[$mm-1]) {return ''}
        return "$dd.$mm.$yyyy";
    } else {
        return '';
    }
}
sub date2localtime {
    # Процедура конфертирует русскоязычную дату DD.MM.YYYY в числовое значение time()
    my $dtin= shift || return 0;
    if ($dtin=~/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4}).*$/) {
        return timelocal(0,0,0,$1,$2-1,$3-1900);
    }
    return 0
}
sub datetime2localtime {
    # Процедура конфертирует русскоязычную датувремя DD.MM.YYYY HH:MM:SS в числовое значение time()
    my $dtin= shift || return 0;
    if ($dtin=~/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4})\s+(\d{1,2})\:(\d{1,2})\:(\d{1,2}).*$/) {
        return timelocal(
                $6 || 0,
                $5 || 0,
                $4 || 0,
                $1 || 1,
                $2 ? $2-1 : 0,
                $3 ? $3-1900 : 0,
            );
    }
    return 0
}
sub visokos {
    my $arg = shift || 1;
    if ((($arg % 4) == 0 ) and not ( (($arg % 100) == 0) and (($arg % 400) != 0) )) {
        return 1;
    } else {
        return 0;
    }
}
sub date2dig {
    # Преобразование даты в формат 02.12.2010 => 20101202
    # date2dig( $date ) # 02.12.2010 => 20101202

    my $val = shift || &localtime2date();
    my $stat=$val=~s/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4}).*$/$3$2$1/;
    $val = '' unless $stat;
    return $val;
}
sub dig2date {
    # Преобразование даты из числового формата YYYYMMDD в русскоязычный формат DD.MM.YYYY
    my $val = shift || date2dig();
    my $stat=$val=~s/^\s*(\d{4})(\d{2})(\d{2}).*$/$3.$2.$1/;
    $val = '' unless $stat;
    return $val;
}
sub date_time2dig {
    # Преобразование даты и времени из русскоязычного формата в числовой формата: YYYYMMDDHHMMSS
    my $val = shift || current_date_time();
    my $stat=$val=~s/^\s*(\d{2})\.+(\d{2})\.+(\d{4})\D+(\d{2}):(\d{2}):(\d{2}).*$/$3$2$1$4$5$6/;
    $val = '' unless $stat;
    return $val;
}
sub dig2date_time {
    # Преобразование даты и времени из числового формата YYYYMMDDHHMMSS в русскоязычный формат DD.MM.YYYY HH:MM:SS
    my $val = shift || date_time2dig();
    my $stat=$val=~s/^\s*(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2}).*$/$3.$2.$1 $4:$5:$6/;
    $val = '' unless $stat;
    return $val;
}
sub basetime {
    # Количество секунд с момента старта скрипта
    return time() - $^T
}

#
# Специфические преобразования и вычисления
# 
sub translate {
  # Транслитерация русских букв в латинские (польскобуквенный вариант)
  my $text = shift || '';

  #$text=~tr/\xA8\xC0-\xDF/\xB8\xE0-\xFF/; # UP -> down
  $text=~tr/\xA8\xC0-\xC5\xC7-\xD6\xDB\xDD/EABWGDEZIJKLMNOPRSTUFHCYE/; # UP
  $text=~s/\xC6/Rz/g;
  $text=~s/\xD7/Cz/g;
  $text=~s/\xD8/Sz/g;
  $text=~s/\xD9/Sz/g;
  $text=~s/\xDA//g;
  $text=~s/\xDC//g;
  $text=~s/\xDE/Ju/g;
  $text=~s/\xDF/Ja/g;

  $text=~tr/\xB8\xE0-\xE5\xE7-\xF6\xFB\xFD/eabwgdezijklmnoprstufhcye/; # down
  $text=~s/\xE6/rz/g;
  $text=~s/\xF7/cz/g;
  $text=~s/\xF8/sz/g;
  $text=~s/\xF9/sz/g;
  $text=~s/\xFA//g;
  $text=~s/\xFC//g;
  $text=~s/\xFE/ju/g;
  $text=~s/\xFF/ja/g;
  #$text=~tr/\x00-\x1F/_/;
  #$text=~s/[,!?:;'<>=*'"`~ ]/_/g; # Замена знаков препинания
  
  return $text;
}
sub variant_stf {
    my $S = shift || '';
    my $length_s = shift || 0;
    my $countpoints;

    $length_s = 3 if $length_s < 3;
    if ($length_s < 6) {
        $countpoints = $length_s - 2;
    }
    else {
        $countpoints = 3;
    }

    my $reallenght = $length_s - $countpoints;

    my ($Snew,$fix,$new_start,$dot,$new_midle,$new_end);
    if (length($S) <= $length_s) {
        $Snew = $S;
    } else {
        $fix= sprintf "%d",($reallenght / 2);
        $new_start = substr($S, 0, ($reallenght - $fix));
        $dot='.';
        $new_midle = $dot x $countpoints;
        $new_end = substr($S,(length($S)-$fix),$fix);
        $new_start=~s/\s+$//;
        $new_end=~s/^\s+//;
        $Snew = $new_start.$new_midle.$new_end;
    }
    return $Snew;
}
sub randomize {
    # Вычисление случайного числа с заданным количеством знаков
    my $digs = shift || return 0;
    my $rstat;
    for (my $i=0; $i<$digs; $i++) {
       $rstat.=int(rand(10));
    }
    $rstat=substr ($rstat,0,abs($digs));
    return "$rstat"
}

#
# Процедуры чтения и записи текстовых массивов из файла/в файл
#
sub load_file {
    # Чтение фала блоком размером в файл
    my $filename = shift || return ''; # АБСОЛЮТНОЕ имя файла
    my $text ='';
    local *FILE;
    if(-e $filename){
        my $ostat = open(FILE,"<",$filename);
        if ($ostat) {
            read(FILE,$text,-s $filename) unless -z $filename;
            close FILE;
        } else {
            _error("[FILE TEXT: Can't open file to load] $!");
        }
    }
    return $text; # Принятый текст
}
sub save_file {
    # Запсиь блока НЕДВОИЧНЫХ данных в файл
    my $filename = shift || return 0; # АБСОЛЮТНОЕ имя файла
    my $text = shift || ''; # Текстовый массив
    local *FILE;
    my $ostat = open(FILE,">",$filename);
    if ($ostat) {
        flock (FILE, 2) or _error("[FILE TEXT: Can't lock file '$filename'] $!");
        print FILE $text;
        close FILE;
    } else {
        _error("[FILE TEXT: Can't open file to write] $!");
    }
    return 1; # статус выполнения операции 
}
#
# Процедуры чтения и записи двоичных массивов из файла/в файл
#
sub file_load {
    # Чтение ДВОИЧНЫХ данных из фала
    my $fn     = shift || '';
    my $onutf8 = shift;
    my $IN;
    return 0 unless $fn;

    if (ref $fn eq 'GLOB') {
        $IN = $fn;
    } else {
        my $ostat = open $IN, '<', $fn;
        unless ($ostat) {
            _error("[FILE BIN: Can't open file to load \'$fn\'] $!");
            return '';
        }
    }
    binmode $IN, ':raw:utf8' if $onutf8;
    binmode $IN unless $onutf8;
    return scalar(do { local $/; <$IN> });
}
sub file_save {
    # Запсиь ДВОИЧНЫХ данных в файл
    my $fn      = shift || '';
    my $content = shift || '';
    my $onutf8 = shift;
    my $OUT;
    return 0 unless $fn;

    my $flc = 0;
    if (ref $fn eq 'GLOB') {
       $OUT = $fn;
    } else {
        my $ostat = open $OUT, '>', $fn;
        unless ($ostat) {
            _error("[FILE BIN: Can't open file to write] $!");
            return 0;
        }
        flock $OUT, 2 or _error("[FILE BIN: Can't lock file \'$fn\']");
        $flc = 1;
    }

    binmode $OUT, ':raw:utf8' if $onutf8;
    binmode $OUT unless $onutf8;
    print $OUT $content;
    close $OUT if $flc;
    return 1; # статус выполнения операции 
}
sub fsave {save_file(@_)} # текстовая запись
sub fload {load_file(@_)} # текстовое чтение
sub bsave {file_save(@_)} # двоичная запись
sub bload {file_load(@_)} # двоичное чтение

sub touch {
    # Трогаем файл (взято с ExtUtils::Command)
    my $fn  = shift || '';
    return 0 unless $fn;
    my $t   = time;
    my $OUT;
    my $ostat = open $OUT, '>>', $fn;
    unless ($ostat) {
        _error("[TOUCH: Can't open file to write] $!");
        return 0;
    }
        
    close $OUT if $ostat;
    utime($t,$t,$fn);
    return 1;
}

sub preparedir {
	# Подготовка директории к работе
    # Ссоздание каталога, если его нет, выставление прав на запись 0777
    my $din = shift || return 0;
    my $chmod = shift || undef; #0777
    
    my @dirs;
    if (ref($din) eq 'HASH') {
        foreach my $k (values %$din) { push @dirs, $k };
    } elsif (ref($din) eq 'ARRAY') {
        @dirs = @$din;
    } else { push @dirs, $din }
    my $stat = 1;
	foreach my $dir (@dirs) {
        mkpath( $dir, {verbose => 0} ) unless -e $dir; # mkdir $dir unless -e $dir;
        #CTK::say("!!!! ",$dir);
        chmod($chmod,$dir) if defined($chmod) && -e $dir;
        unless ($dir && (-d $dir or -l $dir)) {
            $stat = 0;
            cluck("Directory don't prepare: \"$dir\"");
        } 
    }
    return $stat;
}
sub scandirs {
    # Получаем список каталогов [путь,имя]
    my $dir = shift || '/';  # начинать поиск. по умолчанию - корень
   
    my @dirs;
   
    opendir(DIR,$dir) or return @dirs;
    @dirs = grep {!(/^\.+$/) && -d "$dir/$_"} readdir(DIR); # ищем все директории в указаной
    closedir (DIR);
    @dirs = sort {$a cmp $b} @dirs;
    my $cd;
  
    foreach (@dirs) {
        $cd = "$dir/$_";
        $cd =~ s/\/{2,}/\//;
        $_ = [$cd, $_];
    }
  
    return @dirs;
}
sub scanfiles {
    # Получаем список файлов [путь,имя]
    my $dir = shift || '/'; # по умолчанию - корень
    my $mask = shift || qr//; # по умолчанию - все файлы
   
    my @files;
    
    opendir(DIR,$dir) or return @files;
        @files = grep {!(/^\.+$/) && -f "$dir/$_"} readdir(DIR);# ищем все файлы в указаной папке
    closedir (DIR);

    
    @files = grep {/$mask/i} @files if $mask; # выкидываем все файлы не по маске!

    @files = sort {$a cmp $b} @files;
    my $cd;
  
    foreach (@files) {
        $cd = "$dir/$_";
        $cd =~s/\/{2,}/\//;
        $_ = [$cd, $_];
    }
  
    return @files;
}

# Процедуры группы Atom
#
# ftp ftprwtest ftpgetlist getlist getdirlist procexec procexe proccommand proccmd procrun
#
sub ftp {
    # Упрощенная работа с FTP
    #my %ftpct = (
    #    ftphost     => '192.168.1.1',
    #    ftpuser     => 'login',
    #    ftppassword => 'password',
    #    ftpdir      => '~/',
    #    #ftpattr     => {},
    #);
    #my $rfiles = CTK::ftp(\%ftpct, 'ls');
    #my @remotefiles = $rfiles ? grep {!(/^\./)} @$rfiles : ();
    #ftp(\%ftpct, 'put', catfile($dirin,$file), $file);

    my $ftpconnect  = shift || {}; # Параметры коннекта {}
    my $cmd         = shift || ''; # Команда
    my $lfile       = shift || ''; # Локальный файл (с путем)
    my $rfile       = shift || ''; # Удаленный файл (только имя)
    
    # Проверка на вшивость:
    unless ($ftpconnect && (ref($ftpconnect) eq 'HASH') && $ftpconnect->{ftphost}) {
        _exception("Undefined conect's data");
        return undef;
    }

    # Данные для коннекта к FTP-директории и Атрибуты коннекта {}
    my $ftphost     = $ftpconnect ? $ftpconnect->{ftphost}     : '';
    my $ftpuser     = $ftpconnect ? $ftpconnect->{ftpuser}     : '';
    my $ftppassword = $ftpconnect ? $ftpconnect->{ftppassword} : '';
    my $ftpdir      = $ftpconnect ? $ftpconnect->{ftpdir}      : '';
    my $attr        = $ftpconnect &&  $ftpconnect->{ftpattr} ? $ftpconnect->{ftpattr} : {};
    $attr->{Debug}  = (DEBUG && DEBUG == 2) ? 1 : 0;

    # создаем соединение
    my $ftp = Net::FTP->new($ftphost, %$attr)
        or (_debug("FTP: Can't connect to remote FTP server $ftphost: $@") && return undef);
    # логинимся
    $ftp->login($ftpuser, $ftppassword)
        or (_debug("FTP: Can't login to remote FTP server: ", $ftp->message) && return undef);
    # выбираем рабочую директорию
    if($ftpdir && !$ftp->cwd($ftpdir)) {
        _debug("FTP: Can't change FTP working directory \"$ftpdir\": ", $ftp->message);
        return undef;
    }


    my @out; # вывод
    if ( $cmd eq "connect" ){
        # Возвращаем хэндлер на коннект
        return $ftp;
	} elsif ( $cmd eq "ls" ){
		# получаем список в виде массива
		(my @out = $ftp->ls(CTK::WIN ? "" : "-1a" )) 
			or _debug( "FTP: Can't get directory listing (\"$ftpdir\") from remote FTP server $ftphost: ", $ftp->message );
	    $ftp->quit;
	    return [@out];
    } elsif (!$lfile) {
        # не выбран файл - ошибка
		_debug("FTP: No filename given as parameter to FTP command $cmd");
    } elsif ($cmd eq "delete") {
        # удаляем файл
		$ftp->delete($lfile) 
			or _debug( "FTP: Can't delete file \"$lfile\" on remote FTP server $ftphost: ", $ftp->message );
    } elsif ($cmd eq "get") {
        # получаем файл
		$ftp->binary;
		$ftp->get($rfile,$lfile) 
			or _debug("FTP: Can't get file \"$lfile\" from remote FTP server $ftphost: ", $ftp->message);
    } elsif ($cmd eq "put") {
        # отправляем файл
		$ftp->binary;
		$ftp->put($lfile,$rfile) 
			or _debug("FTP: Can't put file \"$lfile\" on remote FTP server $ftphost: ", $ftp->message );
    }

    $ftp->quit; # закрываем соединение и выходим
    return 1;
}
sub ftptest {
    # Проверка RW соединения FTP и возвращение 1 в случае успеха
    my $ftpdata = shift || undef;
    unless ($ftpdata) {
        _error('Нет данных соединения'); # Данные соединения с FTP
        return undef;
    }
    # _debug("Проверка соединения RW с ftp://$ftpdata->{ftphost}...");
    my $vfile = catfile($CTK::DATADIR, CTK::VOIDFILE);
    unless (CTK::VOIDFILE && -e $vfile) {
        _debug("Нет файла VOID: \"$vfile\""); # Данные соединения с FTP
        return undef;
    }
    ftp($ftpdata, 'put', $vfile, CTK::VOIDFILE);
    my $rfiles = ftp($ftpdata,'ls');
    my @remotefiles = $rfiles ? grep {!(/^\./)} @$rfiles : ();
    unless (grep {$_ eq CTK::VOIDFILE} @remotefiles) {
        _debug("Ошибка соединения с FTP {".join(", ",(%$ftpdata))."}");
        return undef;
    }
    ftp($ftpdata, 'delete', CTK::VOIDFILE);
    return 1;
}
sub ftpgetlist {
    # Получение списка файлов на удаленном ресурсе по маске
    my $connect  = shift || {};  # Данные соединения
    my $mask     = shift || qr//; # Маска файлов
    
    my $rfile = ftp($connect, 'ls'); 
    my @files = grep {$_ =~ $mask} ($rfile ? @$rfile : ());
    return [@files];
}
sub getlist {
    # Получение списка файлов в указанной директории по маске
    my $dirin  = shift || '';     # Директория-источник
    my $mask   = shift || qr//;   # Маска поиска файлов

    my @list;
    if (ref($mask) eq 'Regexp') {
        foreach my $fr (scanfiles($dirin,$mask)) {
            push @list, $fr->[1];
        }
    }
    return [@list];
}
sub getdirlist {
    # Получение списка папок в указанной директории по маске
    my $dirin  = shift || '';     # Директория-источник
    my $mask   = shift || qr//;   # Маска поиска файлов

    my @list;
    if (ref($mask) eq 'Regexp') {
        foreach my $fr (scandirs($dirin)) {
            push @list, $fr->[1] if $fr->[1] =~ $mask;
        }
    }
    return [@list];
}
sub procexec {
    # Выполнение внешней команды IPC
    my $icmd = shift || '';     # команда и аргументы (ссылка на массив или строка)
    my $scmd;
    
    if ($icmd && ref($icmd) eq 'ARRAY') {
        $scmd = join " ", @$icmd;;
    } else {
        $scmd = $icmd;
    }
   
    my ($in,$out,$err) = ('','',''); 
    my $pid	= open3(\*IN, \*OUT, \*ERR, $scmd);
	close IN;
	while (<OUT>) { $out .= $_ }
	close OUT;
    while (<ERR>) { $err .= $_ }
	close ERR;
	waitpid($pid, 0);
    _debug("Executable error ($scmd): $err") if $err;
    
    return $out;
}
sub procexe { procexec(@_) }
sub proccommand { procexec(@_) }
sub proccmd { procexec(@_) }
sub procrun { procexec(@_) }
sub exe { procexec(@_) }
sub com { procexec(@_) }
sub execute { procexec(@_) }

#
# Утилитарные процедуры модуля
#
# Smart rearrangement of parameters to allow named parameter calling.
# See CGI::Util
#
sub read_attributes {
    my($order,@param) = @_;
    return () unless @param;

    if (ref($param[0]) eq 'HASH') {
	@param = %{$param[0]};
    } else {
        return @param unless (defined($param[0]) && substr($param[0],0,1) eq '-');
    }

    # map parameters into positional indices
    my ($i,%pos);
    $i = 0;
    foreach (@$order) {
	foreach (ref($_) eq 'ARRAY' ? @$_ : $_) {
            $pos{lc($_)} = $i;
        }
	$i++;
    }

    my (@result,%leftover);
    $#result = $#$order;  # preextend
    while (@param) {
	my $key = lc(shift(@param));
	$key =~ s/^\-//;
        if (exists $pos{$key}) {
	    $result[$pos{$key}] = shift(@param);
	} else {
	    $leftover{$key} = shift(@param);
	}
    }

    push (@result,_make_attributes(\%leftover,1)) if %leftover;
    @result;
}
sub _make_attributes {
    my $attr = shift;
    return () unless $attr && ref($attr) && ref($attr) eq 'HASH';
    my $escape = shift || 0;
    my(@att);
    foreach (keys %{$attr}) {
	my($key) = $_;
        $key=~s/^\-//;
	($key="\L$key") =~ tr/_/-/; # parameters are lower case, use dashes
	my $value = $escape ? $attr->{$_} : $attr->{$_};
	push(@att,defined($attr->{$_}) ? qq/$key="$value"/ : qq/$key/);
    }
    return @att;
}
sub _debug { carp(@_) } # Просто пишем дебаггером
sub _error { carp(@_) } # Пишем в стандартный вывод STDERROR, ТОЛЬКО ДЛЯ СИСТЕМНЫХ ПРОБЛЕМ!!!
sub _exception { confess(@_) } # Пишем в стандартный вывод STDERROR и убиваем, ТОЛЬКО ДЛЯ СИСТЕМНЫХ ПРОБЛЕМ!!!
1;
__END__