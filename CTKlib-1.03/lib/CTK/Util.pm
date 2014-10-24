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
# carp    -- ������ �����
# croak   -- ������ ����� � �������
# cluck   -- ����� �� � �������������
# confess -- ����� � ������������� � �������

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
    # �������� ������ ����������� ������ MIME::Lite � ��������� UTF-8
    # ���������� ������ ��������. 1 - �����, 0 - �������. ������ ���������� � ���
    #
    
    my @args = @_;
    my ($to, $cc, $from, $subject, $message, $type, 
        $sendmail, $charset, $mailer_flags, $smtp, $smtpuser, $smtppass,$att);
    
    # ���� ������
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

    # �� ��������� ������� ������ ������, � ���������� -- ������ ������������
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

    # �������������� ����� ���� � ������ � ��������� ���������
    if ($charset !~ /utf\-?8/i) {
        $subject = to_utf8($subject,$charset);
        $message = to_utf8($message,$charset);
    }
    
    # �������� ������
    my $msg = MIME::Lite->new( 
        From     => $from,
        To       => $to,
        Cc       => $cc,
        Subject  => to_base64($subject),
	    Type     => $type,
        Encoding => 'base64',
        Data     => Encode::encode('UTF-8',$message)
    );
    # ������������� ������� �������
    $msg->attr('content-type.charset' => 'UTF-8');
    $msg->attr('Content-Transfer-Encoding' => 'base64');
    
    # ����� (���� �� ����)
    if ($att) {
        if (ref($att) =~ /HASH/i) {
            $msg->attach(%$att);
        } elsif  (ref($att) =~ /ARRAY/i) {
            foreach (@$att) {
                if (ref($_) =~ /HASH/i) {
                    $msg->attach(%$_);
                } else {
                    _debug("���������� ������������ ������������� ������ ��� ���� � ������������� ������");
                }
            }
        } else {
            _debug("���������� ������������ ������ ��� ���� � ������������� ������");
        }
    }

    # �������� ������
    my $sendstat;
    if ($sendmail && -e $sendmail) {
        # sendmail ������ � �� ����������
        $sendstat = $msg->send(sendmail => "$sendmail $mailer_flags");
        _debug("[SENDMAIL: program sendmail not found! \"$sendmail $mailer_flags\"] $!") unless $sendstat;
                   
    } else {
        # ������� ������������ SMTP ������
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
    # ��������������� ������ � UTF-8 �� ��������� ���������
    # to_utf8( $string, $charset ) # charset is 'Windows-1251' as default

    my $ss = shift || return ''; # ���������
    my $ch = shift || 'Windows-1251'; # �������������
    return Encode::decode($ch,$ss)
}
sub to_windows1251 {
    my $ss = shift || return ''; # ���������
    my $ch = shift || 'Windows-1251'; # �������������
    return Encode::encode($ch,$ss)
}
sub CP1251toUTF8 {to_utf8(@_)};
sub UTF8toCP1251 {to_windows1251(@_)};
sub to_base64 {
    # ��������������� ������ UTF-8  � base64
    # to_base64( $utf8_string )

    my $ss = shift || ''; # ���������
    return '=?UTF-8?B?'.MIME::Base64::encode(Encode::encode('UTF-8',$ss),'').'?=';
}

#
# ��������� �������
# 
sub slash {
    #
    # ��������� ������� ��������� ������ �� ������ ������� �� 
    #
    my $data_staring = shift || '';

    $data_staring =~ s/\\/\\\\/g;
    $data_staring =~ s/'/\\'/g;

    return $data_staring;
}
sub tag {
    #
    # ��������� ������� ��������� ������ �� ������ ������� �� 
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
    # ��������� ��������������� ����
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
    # ���������
    my $ss  = '<![CDATA[';
    my $sf  = ']]>';
    if (defined $s) {
        return to_utf8($ss).$s.to_utf8($sf);
    }
    return '';
}
sub unescape($) { 
    # �������� �������������� URL ������������ ���� &amp; => &
    # unescape( $string )
    
    my $c = shift || return ''; 
    $c=~s/&amp;/&/g; 
    return $c; 
}
sub dformat { # �����, ������ ��� ������ � ���� ������ �� ���
    # �������� �� ������� ������� ���������� ��������� �� �������������
    my $fmt = shift || ''; # ������ ��� ������
    my $fd  = shift || {}; # ������ ��� ������
    $fmt =~ s/\[(.+?)\]/(defined $fd->{uc($1)} ? $fd->{uc($1)} : '')/eg;
    return $fmt;
}
sub fformat { # �����, ��� �����
    # �������� �� ������� ������� ���������� ��������� �� �����������
    # [FILENAME] -- ������ ��� �����
    # [FILEEXT]  -- ������ ���������� �����
    # [FILE]     -- ��� ��� ����� � ����������� ������
    my $fmt = shift || ''; # ������. �������� ����: [FILENAME]-blah-blah-blah.[FILEEXT]
    my $fin = shift || ''; # ��� ����� ������� ����� �������� "�� �������", �������� void.txt
    
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
# ���������������� �������
# 
sub correct_number {
    # ����������� �������� � �����
    my $var = shift || 0;
    my $sep = shift || "`";
    1 while $var=~s/(\d)(\d\d\d)(?!\d)/$1$sep$2/;
    return $var;
}
sub correct_dig {
    # ��������� ������������� �������� �� ���� �����. ���� �������� ������� �� �� ���� �� ������������ 0
    my $dig=shift || '';
    if ($dig =~/^(\d{1,11})$/) {
        return $1;    
    }
    return 0;
}

#
# ���������� ��� � �������
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
    # �������������� ������� � ���� ������� 02.12.2010
    # localtime2date ( time() ) # => 02.12.2010

    my $dandt=shift || time;
    my @dt=localtime($dandt);
    #my $cdt= (($dt[3]>9)?$dt[3]:'0'.$dt[3]).'.'.(($dt[4]+1>9)?$dt[4]+1:'0'.($dt[4]+1)).'.'.($dt[5]+1900);
    #return $cdt;
    return sprintf (
        "%02d.%02d.%04d",
        $dt[3], # ����
        $dt[4]+1, # �����
        $dt[5]+1900 # ���
    );
}
sub localtime2date_time {
    my $dandt=shift || time;
    my @dt=localtime($dandt);
    #my $cdt= (($dt[3]>9)?$dt[3]:'0'.$dt[3]).'.'.(($dt[4]+1>9)?$dt[4]+1:'0'.($dt[4]+1)).'.'.($dt[5]+1900)." ".(($dt[2]>9)?$dt[2]:'0'.$dt[2]).":".(($dt[1]>9)?$dt[1]:'0'.$dt[1]).':'.(($dt[0]>9)?$dt[0]:'0'.$dt[0]);
    #return $cdt;
    return sprintf (
        "%02d.%02d.%04d %02d:%02d:%02d",
        $dt[3], # ����
        $dt[4]+1, # �����
        $dt[5]+1900, # ���
        $dt[2], # ���
        $dt[1], # ���
        $dt[0]  # ���
    );

}
sub correct_date {
    #
    # ���������� ���� � ���������� ���������� ������ dd.mm.yyyy
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
    # ��������� ������������ ������������� ���� DD.MM.YYYY � �������� �������� time()
    my $dtin= shift || return 0;
    if ($dtin=~/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4}).*$/) {
        return timelocal(0,0,0,$1,$2-1,$3-1900);
    }
    return 0
}
sub datetime2localtime {
    # ��������� ������������ ������������� ��������� DD.MM.YYYY HH:MM:SS � �������� �������� time()
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
    # �������������� ���� � ������ 02.12.2010 => 20101202
    # date2dig( $date ) # 02.12.2010 => 20101202

    my $val = shift || &localtime2date();
    my $stat=$val=~s/^\s*(\d{1,2})\.+(\d{1,2})\.+(\d{4}).*$/$3$2$1/;
    $val = '' unless $stat;
    return $val;
}
sub dig2date {
    # �������������� ���� �� ��������� ������� YYYYMMDD � ������������� ������ DD.MM.YYYY
    my $val = shift || date2dig();
    my $stat=$val=~s/^\s*(\d{4})(\d{2})(\d{2}).*$/$3.$2.$1/;
    $val = '' unless $stat;
    return $val;
}
sub date_time2dig {
    # �������������� ���� � ������� �� �������������� ������� � �������� �������: YYYYMMDDHHMMSS
    my $val = shift || current_date_time();
    my $stat=$val=~s/^\s*(\d{2})\.+(\d{2})\.+(\d{4})\D+(\d{2}):(\d{2}):(\d{2}).*$/$3$2$1$4$5$6/;
    $val = '' unless $stat;
    return $val;
}
sub dig2date_time {
    # �������������� ���� � ������� �� ��������� ������� YYYYMMDDHHMMSS � ������������� ������ DD.MM.YYYY HH:MM:SS
    my $val = shift || date_time2dig();
    my $stat=$val=~s/^\s*(\d{4})(\d{2})(\d{2})(\d{2})(\d{2})(\d{2}).*$/$3.$2.$1 $4:$5:$6/;
    $val = '' unless $stat;
    return $val;
}
sub basetime {
    # ���������� ������ � ������� ������ �������
    return time() - $^T
}

#
# ������������� �������������� � ����������
# 
sub translate {
  # �������������� ������� ���� � ��������� (���������������� �������)
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
  #$text=~s/[,!?:;'<>=*'"`~ ]/_/g; # ������ ������ ����������
  
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
    # ���������� ���������� ����� � �������� ����������� ������
    my $digs = shift || return 0;
    my $rstat;
    for (my $i=0; $i<$digs; $i++) {
       $rstat.=int(rand(10));
    }
    $rstat=substr ($rstat,0,abs($digs));
    return "$rstat"
}

#
# ��������� ������ � ������ ��������� �������� �� �����/� ����
#
sub load_file {
    # ������ ���� ������ �������� � ����
    my $filename = shift || return ''; # ���������� ��� �����
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
    return $text; # �������� �����
}
sub save_file {
    # ������ ����� ���������� ������ � ����
    my $filename = shift || return 0; # ���������� ��� �����
    my $text = shift || ''; # ��������� ������
    local *FILE;
    my $ostat = open(FILE,">",$filename);
    if ($ostat) {
        flock (FILE, 2) or _error("[FILE TEXT: Can't lock file '$filename'] $!");
        print FILE $text;
        close FILE;
    } else {
        _error("[FILE TEXT: Can't open file to write] $!");
    }
    return 1; # ������ ���������� �������� 
}
#
# ��������� ������ � ������ �������� �������� �� �����/� ����
#
sub file_load {
    # ������ �������� ������ �� ����
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
    # ������ �������� ������ � ����
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
    return 1; # ������ ���������� �������� 
}
sub fsave {save_file(@_)} # ��������� ������
sub fload {load_file(@_)} # ��������� ������
sub bsave {file_save(@_)} # �������� ������
sub bload {file_load(@_)} # �������� ������

sub touch {
    # ������� ���� (����� � ExtUtils::Command)
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
	# ���������� ���������� � ������
    # ��������� ��������, ���� ��� ���, ����������� ���� �� ������ 0777
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
    # �������� ������ ��������� [����,���]
    my $dir = shift || '/';  # �������� �����. �� ��������� - ������
   
    my @dirs;
   
    opendir(DIR,$dir) or return @dirs;
    @dirs = grep {!(/^\.+$/) && -d "$dir/$_"} readdir(DIR); # ���� ��� ���������� � ��������
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
    # �������� ������ ������ [����,���]
    my $dir = shift || '/'; # �� ��������� - ������
    my $mask = shift || qr//; # �� ��������� - ��� �����
   
    my @files;
    
    opendir(DIR,$dir) or return @files;
        @files = grep {!(/^\.+$/) && -f "$dir/$_"} readdir(DIR);# ���� ��� ����� � �������� �����
    closedir (DIR);

    
    @files = grep {/$mask/i} @files if $mask; # ���������� ��� ����� �� �� �����!

    @files = sort {$a cmp $b} @files;
    my $cd;
  
    foreach (@files) {
        $cd = "$dir/$_";
        $cd =~s/\/{2,}/\//;
        $_ = [$cd, $_];
    }
  
    return @files;
}

# ��������� ������ Atom
#
# ftp ftprwtest ftpgetlist getlist getdirlist procexec procexe proccommand proccmd procrun
#
sub ftp {
    # ���������� ������ � FTP
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

    my $ftpconnect  = shift || {}; # ��������� �������� {}
    my $cmd         = shift || ''; # �������
    my $lfile       = shift || ''; # ��������� ���� (� �����)
    my $rfile       = shift || ''; # ��������� ���� (������ ���)
    
    # �������� �� ��������:
    unless ($ftpconnect && (ref($ftpconnect) eq 'HASH') && $ftpconnect->{ftphost}) {
        _exception("Undefined conect's data");
        return undef;
    }

    # ������ ��� �������� � FTP-���������� � �������� �������� {}
    my $ftphost     = $ftpconnect ? $ftpconnect->{ftphost}     : '';
    my $ftpuser     = $ftpconnect ? $ftpconnect->{ftpuser}     : '';
    my $ftppassword = $ftpconnect ? $ftpconnect->{ftppassword} : '';
    my $ftpdir      = $ftpconnect ? $ftpconnect->{ftpdir}      : '';
    my $attr        = $ftpconnect &&  $ftpconnect->{ftpattr} ? $ftpconnect->{ftpattr} : {};
    $attr->{Debug}  = (DEBUG && DEBUG == 2) ? 1 : 0;

    # ������� ����������
    my $ftp = Net::FTP->new($ftphost, %$attr)
        or (_debug("FTP: Can't connect to remote FTP server $ftphost: $@") && return undef);
    # ���������
    $ftp->login($ftpuser, $ftppassword)
        or (_debug("FTP: Can't login to remote FTP server: ", $ftp->message) && return undef);
    # �������� ������� ����������
    if($ftpdir && !$ftp->cwd($ftpdir)) {
        _debug("FTP: Can't change FTP working directory \"$ftpdir\": ", $ftp->message);
        return undef;
    }


    my @out; # �����
    if ( $cmd eq "connect" ){
        # ���������� ������� �� �������
        return $ftp;
	} elsif ( $cmd eq "ls" ){
		# �������� ������ � ���� �������
		(my @out = $ftp->ls(CTK::WIN ? "" : "-1a" )) 
			or _debug( "FTP: Can't get directory listing (\"$ftpdir\") from remote FTP server $ftphost: ", $ftp->message );
	    $ftp->quit;
	    return [@out];
    } elsif (!$lfile) {
        # �� ������ ���� - ������
		_debug("FTP: No filename given as parameter to FTP command $cmd");
    } elsif ($cmd eq "delete") {
        # ������� ����
		$ftp->delete($lfile) 
			or _debug( "FTP: Can't delete file \"$lfile\" on remote FTP server $ftphost: ", $ftp->message );
    } elsif ($cmd eq "get") {
        # �������� ����
		$ftp->binary;
		$ftp->get($rfile,$lfile) 
			or _debug("FTP: Can't get file \"$lfile\" from remote FTP server $ftphost: ", $ftp->message);
    } elsif ($cmd eq "put") {
        # ���������� ����
		$ftp->binary;
		$ftp->put($lfile,$rfile) 
			or _debug("FTP: Can't put file \"$lfile\" on remote FTP server $ftphost: ", $ftp->message );
    }

    $ftp->quit; # ��������� ���������� � �������
    return 1;
}
sub ftptest {
    # �������� RW ���������� FTP � ����������� 1 � ������ ������
    my $ftpdata = shift || undef;
    unless ($ftpdata) {
        _error('��� ������ ����������'); # ������ ���������� � FTP
        return undef;
    }
    # _debug("�������� ���������� RW � ftp://$ftpdata->{ftphost}...");
    my $vfile = catfile($CTK::DATADIR, CTK::VOIDFILE);
    unless (CTK::VOIDFILE && -e $vfile) {
        _debug("��� ����� VOID: \"$vfile\""); # ������ ���������� � FTP
        return undef;
    }
    ftp($ftpdata, 'put', $vfile, CTK::VOIDFILE);
    my $rfiles = ftp($ftpdata,'ls');
    my @remotefiles = $rfiles ? grep {!(/^\./)} @$rfiles : ();
    unless (grep {$_ eq CTK::VOIDFILE} @remotefiles) {
        _debug("������ ���������� � FTP {".join(", ",(%$ftpdata))."}");
        return undef;
    }
    ftp($ftpdata, 'delete', CTK::VOIDFILE);
    return 1;
}
sub ftpgetlist {
    # ��������� ������ ������ �� ��������� ������� �� �����
    my $connect  = shift || {};  # ������ ����������
    my $mask     = shift || qr//; # ����� ������
    
    my $rfile = ftp($connect, 'ls'); 
    my @files = grep {$_ =~ $mask} ($rfile ? @$rfile : ());
    return [@files];
}
sub getlist {
    # ��������� ������ ������ � ��������� ���������� �� �����
    my $dirin  = shift || '';     # ����������-��������
    my $mask   = shift || qr//;   # ����� ������ ������

    my @list;
    if (ref($mask) eq 'Regexp') {
        foreach my $fr (scanfiles($dirin,$mask)) {
            push @list, $fr->[1];
        }
    }
    return [@list];
}
sub getdirlist {
    # ��������� ������ ����� � ��������� ���������� �� �����
    my $dirin  = shift || '';     # ����������-��������
    my $mask   = shift || qr//;   # ����� ������ ������

    my @list;
    if (ref($mask) eq 'Regexp') {
        foreach my $fr (scandirs($dirin)) {
            push @list, $fr->[1] if $fr->[1] =~ $mask;
        }
    }
    return [@list];
}
sub procexec {
    # ���������� ������� ������� IPC
    my $icmd = shift || '';     # ������� � ��������� (������ �� ������ ��� ������)
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
# ����������� ��������� ������
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
sub _debug { carp(@_) } # ������ ����� ����������
sub _error { carp(@_) } # ����� � ����������� ����� STDERROR, ������ ��� ��������� �������!!!
sub _exception { confess(@_) } # ����� � ����������� ����� STDERROR � �������, ������ ��� ��������� �������!!!
1;
__END__