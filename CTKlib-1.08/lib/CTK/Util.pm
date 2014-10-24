package CTK::Util; # $Id: Util.pm 97 2013-01-31 21:37:15Z minus $
use strict; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::Util - CTK Utilities

=head1 VERSION

Version 1.00

=head1 REVISION 

$Revision: 97 $

=head1 SYNOPSIS

    use CTK::Util;
    use CTK::Util qw( :ALL ); # Export only ALL tag. See TAGS section
    
    my @ls = ls(".");
    
    # or (for CTK module)
    
    use CTK;
    my @ls = CTK::ls(".");
    
    # or (for core and extended subroutines only)
    
    use CTK;
    my $c = new CTK;
    my $prefix = $c->getsyscfg("prefix");
    
=head1 DESCRIPTION

Public subroutines

=head2 SUBROUTINES

...

=head3 eqtime

    eqtime("source/file", "destination/file");

Sets modified time of destination to that of source.

=head3 escape

    $safe = escape("10% is enough\n");
    
Replaces each unsafe character in the string "10% is enough\n" with the corresponding
escape sequence and returns the result.  The string argument should
be a string of bytes.

See also L<URI::Escape>

=head3 shuffle

    @cards = shuffle(0..51); # 0..51 in a random order

Returns the elements of LIST in a random order

Pure-Perl implementation of Function List::Util::PP::shuffle
(Copyright (c) 1997-2009 Graham Barr <gbarr@pobox.com>. All rights reserved.)

See also L<List::Util>

=head3 touch

    touch("file");

Makes file exist, with current timestamp

=head2 UTILITY SUBROUTINES

=head3 sendmail, send_mail

    my $sent = sendmail(
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

=head3 unescape

    $str = unescape(escape("10% is enough\n"));
    
Returns a string with each %XX sequence replaced with the actual byte (octet).

This does the same as:

    $string =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;

See also L<URI::Escape>
    
=head2 EXTENDED SUBROUTINES

=head3 cachedir

    my $value = cachedir();
    my $value = $c->cachedir();

For example value can be set as: /var/cache

/var/cache is intended for cached data from applications. Such data is locally generated as a result of
time-consuming I/O or calculation. The application must be able to regenerate or restore the data. Unlike
/var/spool, the cached files can be deleted without data loss. The data must remain valid between invocations
of the application and rebooting the system.

Files located under /var/cache may be expired in an application specific manner, by the system administrator,
or both. The application must always be able to recover from manual deletion of these files (generally because of
a disk space shortage). No other requirements are made on the data format of the cache directories.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> cachedir

=head3 docdir

    my $value = docdir();
    my $value = $c->docdir();
    
For example value can be set as: /usr/share/doc

See <Sys::Path> docdir

=head3 localstatedir

    my $value = localstatedir();
    my $value = $c->localstatedir();

For example value can be set as: /var

/var - $Config::Config{'prefix'}

/var contains variable data files. This includes spool directories and files, administrative and logging data, and
transient and temporary files.
Some portions of /var are not shareable between different systems. For instance, /var/log, /var/lock, and
/var/run. Other portions may be shared, notably /var/mail, /var/cache/man, /var/cache/fonts, and
/var/spool/news.

/var is specified here in order to make it possible to mount /usr read-only. Everything that once went into /usr
that is written to during system operation (as opposed to installation and software maintenance) must be in /var.
If /var cannot be made a separate partition, it is often preferable to move /var out of the root partition and into
the /usr partition. (This is sometimes done to reduce the size of the root partition or when space runs low in the
root partition.) However, /var must not be linked to /usr because this makes separation of /usr and /var
more difficult and is likely to create a naming conflict. Instead, link /var to /usr/var.

Applications must generally not add directories to the top level of /var. Such directories should only be added if
they have some system-wide implication, and in consultation with the FHS mailing list.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> localstatedir

=head3 localedir

    my $value = localedir();
    my $value = $c->localedir();

For example value can be set as: /usr/share/locale

See L<Sys::Path> localedir

=head3 lockdir

    my $value = lockdir();
    my $value = $c->lockdir();

For example value can be set as: /var/lock

Lock files should be stored within the /var/lock directory structure.
Lock files for devices and other resources shared by multiple applications, such as the serial device lock files that
were originally found in either /usr/spool/locks or /usr/spool/uucp, must now be stored in /var/lock.
The naming convention which must be used is "LCK.." followed by the base name of the device. For example, to
lock /dev/ttyS0 the file "LCK..ttyS0" would be created. 5

The format used for the contents of such lock files must be the HDB UUCP lock file format. The HDB format is
to store the process identifier (PID) as a ten byte ASCII decimal number, with a trailing newline. For example, if
process 1230 holds a lock file, it would contain the eleven characters: space, space, space, space, space, space,
one, two, three, zero, and newline.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> lockdir

=head3 prefixdir

    my $value = prefixdir();
    my $value = $c->prefixdir();

For example value can be set as: /usr

/usr - $Config::Config{'prefix'}

Is a helper function and should not be used directly.

/usr is the second major section of the filesystem. /usr is shareable, read-only data. That means that /usr
should be shareable between various FHS-compliant hosts and must not be written to. Any information that is
host-specific or varies with time is stored elsewhere.

Large software packages must not use a direct subdirectory under the /usr hierarchy.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> prefix

=head3 rundir

    my $value = rundir();
    my $value = $c->rundir();

For example value can be set as: /var/run

This directory contains system information data describing the system since it was booted. Files under this
directory must be cleared (removed or truncated as appropriate) at the beginning of the boot process. Programs
may have a subdirectory of /var/run; this is encouraged for programs that use more than one run-time file. 7
Process identifier (PID) files, which were originally placed in /etc, must be placed in /var/run. The naming
convention for PID files is <program-name>.pid. For example, the crond PID file is named
/var/run/crond.pid.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> rundir

=head3 sharedir

    my $value = sharedir();
    my $value = $c->sharedir();

For example value can be set as: /usr/share

The /usr/share hierarchy is for all read-only architecture independent data files. 10
This hierarchy is intended to be shareable among all architecture platforms of a given OS; thus, for example, a
site with i386, Alpha, and PPC platforms might maintain a single /usr/share directory that is
centrally-mounted. Note, however, that /usr/share is generally not intended to be shared by different OSes or
by different releases of the same OS.

Any program or package which contains or requires data that doesn�t need to be modified should store that data
in /usr/share (or /usr/local/share, if installed locally). It is recommended that a subdirectory be used in
/usr/share for this purpose.

Game data stored in /usr/share/games must be purely static data. Any modifiable files, such as score files,
game play logs, and so forth, should be placed in /var/games.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> datadir

=head3 sharedstatedir

    my $value = sharedstatedir();
    my $value = $c->sharedstatedir();

For example value can be set as: /var/lib

This hierarchy holds state information pertaining to an application or the system. State information is data that
programs modify while they run, and that pertains to one specific host. Users must never need to modify files in
/var/lib to configure a package�s operation.

State information is generally used to preserve the condition of an application (or a group of inter-related
applications) between invocations and between different instances of the same application. State information
should generally remain valid after a reboot, should not be logging output, and should not be spooled data.

An application (or a group of inter-related applications) must use a subdirectory of /var/lib for its data. There
is one required subdirectory, /var/lib/misc, which is intended for state files that don�t need a subdirectory;
the other subdirectories should only be present if the application in question is included in the distribution.

/var/lib/<name> is the location that must be used for all distribution packaging support. Different
distributions may use different names, of course.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> sharedstatedir

=head3 spooldir

    my $value = spooldir();
    my $value = $c->spooldir();

For example value can be set as: /var/spool

/var/spool contains data which is awaiting some kind of later processing. Data in /var/spool represents
work to be done in the future (by a program, user, or administrator); often data is deleted after it has been
processed.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> spooldir

=head3 srvdir

    my $value = srvdir();
    my $value = $c->srvdir();

For example value can be set as: /srv

/srv contains site-specific data which is served by this system.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> srvdir

=head3 sysconfdir

    my $value = sysconfdir();
    my $value = $c->sysconfdir();

For example value can be set as: /etc

The /etc hierarchy contains configuration files. A "configuration file" is a local file used to control the operation
of a program; it must be static and cannot be an executable binary.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> sysconfdir

=head3 syslogdir

    my $value = syslogdir();
    my $value = $c->syslogdir();

For example value can be set as: /var/log

This directory contains miscellaneous log files. Most logs must be written to this directory or an appropriate
subdirectory.

See L<http://www.pathname.com/fhs/pub/> and L<Sys::Path> logdir

=head3 webdir

    my $value = webdir();
    my $value = $c->webdir();

For example value can be set as: /var/www

Directory where distribution put static web files.

See L<Sys::Path> webdir

=head2 CORE SUBROUTINES

=head3 carp, croak, cluck, confess

This is the L<Carp> functions, and exported here for historical reasons.

=over 4

=item B<carp>

Warn user (from perspective of caller)

    carp "string trimmed to 80 chars";

=item B<croak>

Die of errors (from perspective of caller)

    croak "We're outta here!";

=item B<cluck>

Warn user (more detailed what carp with stack backtrace)

    cluck "This is how we got here!";

=item B<confess>
        
Die of errors with stack backtrace

    confess "not implemented";

=back

=head3 getsyscfg, syscfg 

Returns all hash %Config from system module L<Config> or one value of this hash

    my %syscfg = getsyscfg();
    my $prefix = getsyscfg("prefix");
    # or
    my %syscfg = $c->getsyscfg();
    my $prefix = $c->getsyscfg("prefix");

See L<Config> module for details
    
=head3 isos

Returns true or false if the OS name is of the current value of C<$^O>

    isos('mswin32') ? "OK" : "NO";
    # or
    $c->isos('mswin32') ? "OK" : "NO";
    
See L<Perl::OSType> for details

=head3 isostype

Given an OS type and OS name, returns true or false if the OS name is of the
given type.

    isostype('Windows') ? "OK" : "NO";
    isostype('Unix', 'dragonfly') ? "OK" : "NO";
    # or
    $c->isos('Windows') ? "OK" : "NO";
    $c->isostype('Unix', 'dragonfly') ? "OK" : "NO";

See L<Perl::OSType> C<is_os_type>

=head3 read_attributes

Smart rearrangement of parameters to allow named parameter calling.
We do the rearrangement if the first parameter begins with a -

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

See L<CGI::Util>

=head2 TAGS

=head3 ALL, DEFAULT

Export all subroutines, default

=head3 BASE

Export only base subroutines

=head3 FORMAT

Export only text format subroutines

=head3 DATE

Export only date and time subroutines

=head3 FILE

Export only file and directories subroutines

=head3 UTIL

Export only utility subroutines

=head3 ATOM

Export only processing subroutines

=head3 API

Export only inerface subroutines

=head1 SEE ALSO

L<MIME::Lite>, L<CGI::Util>, L<Time::Local>, L<Net::FTP>, L<IPC::Open3>, L<List::Util>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use constant {
    DEBUG     => 1, # 0 - off, 1 - on, 2 - all (+ http headers and other)
    WIN       => $^O =~ /mswin/i ? 1 : 0,
    NULL      => $^O =~ /mswin/i ? 'NUL' : '/dev/null',
    TONULL    => $^O =~ /mswin/i ? '>NUL 2>&1' : '>/dev/null 2>&1',
    ERR2OUT   => '2>&1',
    VOIDFILE  => 'void.txt',
};

use vars qw/$VERSION/;
$VERSION = q/$Revision: 97 $/ =~ /(\d+\.?\d*)/ ? sprintf("%.2f",($1+100)/100) : '1.00';

use Time::Local;
use File::Spec::Functions qw/
        catdir catfile rootdir tmpdir updir curdir 
        path splitpath splitdir abs2rel rel2abs
    /;
use MIME::Base64;
use MIME::Lite;
use Net::FTP;
use File::Path; # mkpath / rmtree
use IPC::Open3;
use Symbol;
use Cwd;

use Carp qw/carp croak cluck confess/;
# carp    -- ������ �����
# croak   -- ������ ����� � �������
# cluck   -- ����� �� � �������������
# confess -- ����� � ������������� � �������

use base qw /Exporter/;
my @est_core = qw(
        syscfg getsyscfg isos isostype
        carp croak cluck confess
        read_attributes
    );
my @est_encoding = qw(
        to_utf8 to_windows1251 CP1251toUTF8 UTF8toCP1251 to_base64
    );
my @est_format = qw(
        escape unescape slash tag tag_create cdata dformat fformat splitformat
        correct_number correct_dig
        translate variant_stf randomize randchars shuffle
    );
my @est_datetime = qw(
        current_date current_date_time localtime2date localtime2date_time correct_date date2localtime
        datetime2localtime visokos date2dig dig2date date_time2dig dig2date_time basetime
    );
my @est_file = qw(
        load_file save_file file_load file_save fsave fload bsave bload touch eqtime
    );
my @est_dir = qw(
        ls scandirs scanfiles
        preparedir
        catdir catfile rootdir tmpdir updir curdir path splitpath splitdir
        prefixdir localstatedir sysconfdir srvdir
        sharedir docdir localedir cachedir syslogdir spooldir rundir lockdir sharedstatedir webdir
    );
my @est_util = qw(
        sendmail send_mail
        ftp ftptest ftpgetlist getlist getdirlist 
        procexec procexe proccommand proccmd procrun exe com execute
    );

our @EXPORT = (
        @est_core, @est_encoding, @est_format, @est_datetime, 
        @est_file, @est_dir, @est_util,
    );
our @EXPORT_OK = @EXPORT;
our %EXPORT_TAGS = (
        ALL     => [@EXPORT],
        DEFAULT => [@EXPORT],
        BASE    => [
                @est_core,
                @est_encoding,
                @est_format,
                @est_file,
                @est_util,
            ],
        FORMAT  => [
                @est_encoding,
                @est_format,
            ],
        DATE    => [@est_datetime],
        FILE    => [@est_file],
        UTIL    => [
                @est_core,
                @est_dir,
                @est_util,
            ],
        ATOM   => [
                @est_dir,
                @est_util,
            ],
        API    => [
                @est_core,
                @est_dir,
            ],
    );

# ������ OOP ������� ������ ���������� ������ ������ ����� ������, ��� ��������� �������
# ������ ���� ����� ��������!!!
push @CTK::Util::ISA, qw/CTK::Util::SysConfig/;

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
sub sendmail { goto &send_mail }
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
sub CP1251toUTF8 { goto &to_utf8 };
sub UTF8toCP1251 { goto &to_windows1251 };
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
sub escape { # Percent-encoding, also known as URL encoding
    my $toencode = shift;
    return '' unless defined($toencode);
    $toencode =~ s/([^a-zA-Z0-9_.~-])/uc(sprintf("%%%02x",ord($1)))/eg;
    return $toencode;
}
sub unescape { # Percent-decoding, also known as URL decoding
    my $todecode = shift;
    return '' unless defined($todecode);
    $todecode =~ tr/+/ /; # pluses become spaces
    $todecode =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $todecode;
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
sub splitformat { goto &fformat }
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
sub randchars {
    # ���������� ���������� ����������� �������� � �������� ����������� ������ � �������� ��������
	my $l = shift || return '';
	return '' unless $l =~/^\d+$/;
    my $arr = shift;

	my $result = '';
	my @chars = ($arr && ref($arr) eq 'ARRAY') ? (@$arr) : (0..9,'a'..'z','A'..'Z');
	$result .= $chars[(int(rand($#chars+1)))] for (1..$l);

	return $result;
}
sub shuffle {
    # ��������� ��������� ������ �� ���������� ������ List::Util::PP
    return unless @_;
    my @a=\(@_);
    my $n;
    my $i=@_;
    map {
        $n = rand($i--);
        (${$a[$n]}, $a[$n] = $a[$i])[0];
    } @_;
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
sub fsave { goto &save_file } # ��������� ������
sub fload { goto &load_file } # ��������� ������
sub bsave { goto &file_save } # �������� ������
sub bload { goto &file_load } # �������� ������

#
# �������� ��������� � ��������� ������ � ���������� � �������� ���������
#
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
sub eqtime {
    # ������ ���� ����� �� ����� �������� � �����������
    my $src = shift || '';
    my $dst = shift || '';

    unless ($src && -e $src) {
        _error("[EQTIME: Can't open file to read] $!");
        return 0;
    }
    unless (utime((stat($src))[8,9],$dst)) {
        _error("[EQTIME: Can't change access and modification times on file] $!");
        return 0;
    }
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
    my $dir = shift || cwd() || curdir() || '.'; # �� ��������� - ������� �������
    my $mask = shift || ''; # �� ��������� - ��� �����
   
    my @dirs;
   
    @dirs = grep {!(/^\.+$/) && -d catdir($dir,$_)} ls($dir, $mask);
    @dirs = sort {$a cmp $b} @dirs;
  
    return map {[catfile($dir,$_), $_]} @dirs;
}
sub scanfiles {
    # �������� ������ ������ [����,���]
    my $dir = shift || cwd() || curdir() || '.'; # �� ��������� - ������� �������
    my $mask = shift || ''; # �� ��������� - ��� �����
   
    my @files;
    @files = grep { -f catfile($dir,$_)} ls($dir, $mask);
    @files = sort {$a cmp $b} @files;
  
    return map {[catfile($dir,$_), $_]} @files;
}
sub ls {
    # �������� ������ ��������
    my $dir = shift || curdir() || '.'; # �� ��������� - ������� �������
    my $mask = shift || ''; # �� ��������� - ��� �����
    
    my @fds;
    
    my $dh = gensym();
    unless (opendir($dh,$dir)) {
        _error("[LS: Can't open directory \"$dir\"] $!");
        return @fds;
    }
     
    @fds = readdir($dh);# ���� ��� ����� � �������� �����
    closedir($dh);

    @fds = grep {/$mask/i} @fds if $mask; # ���������� ��� ����� �� �� �����!
    
    return @fds;
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
    #    voidfile    => './void.txt',
    #    #ftpattr    => {},
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
		(my @out = $ftp->ls(WIN ? "" : "-1a" )) 
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
    my $vfile = '';
    if ($ftpdata->{voidfile}) {
        $vfile = $ftpdata->{voidfile};
    } else {
        $vfile = catfile(tmpdir(),VOIDFILE);
        touch($vfile);
        
    }
    unless (-e $vfile) {
        _debug("��� ����� VOID: \"$vfile\""); # ������ ���������� � FTP
        return undef;
    }
    ftp($ftpdata, 'put', $vfile, VOIDFILE);
    my $rfiles = ftp($ftpdata,'ls');
    my @remotefiles = $rfiles ? grep {!(/^\./)} @$rfiles : ();
    unless (grep {$_ eq VOIDFILE} @remotefiles) {
        _debug("������ ���������� � FTP {".join(", ",(%$ftpdata))."}");
        return undef;
    }
    ftp($ftpdata, 'delete', VOIDFILE);
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
sub procexe { goto &procexec }
sub proccommand { goto &procexec }
sub proccmd { goto &procexec }
sub procrun { goto &procexec }
sub exe { goto &procexec }
sub com { goto &procexec }
sub execute { goto &procexec }


#
# ����������� ���������� (Extended)
#

#
# ������� ������������ �� ������� ������ ������ Sys::Path
#
# prefixdir localstatedir sysconfdir srvdir
# sharedir docdir localedir cachedir syslogdir spooldir rundir lockdir sharedstatedir webdir
#
sub prefixdir { 
    my $pfx = __PACKAGE__->ext_syscfg('prefix') ;
    return defined $pfx ? $pfx : '';
}
sub localstatedir {
    my $pfx = prefixdir();
    if ($pfx eq '/usr') {
        return '/var';
    } elsif ($pfx eq '/usr/local') {
        return '/var';
    }
	return catdir($pfx, 'var');
}
sub sysconfdir {
    my $pfx = prefixdir();
	return $pfx eq '/usr' ? '/etc' : catdir($pfx, 'etc');
}
sub srvdir {
    my $pfx = prefixdir();
    if ($pfx eq '/usr') {
        return '/srv';
    } elsif ($pfx eq '/usr/local') {
        return '/srv';
    }
	return catdir($pfx, 'srv');
}
sub webdir {
    my $pfx = prefixdir();
    return $pfx eq '/usr' ? '/var/www' : catdir($pfx, 'www');
}
sub sharedir        { catdir(prefixdir(), 'share') }
sub docdir          { catdir(prefixdir(), 'share', 'doc') }
sub localedir       { catdir(prefixdir(), 'share', 'locale') }
sub cachedir        { catdir(localstatedir(), 'cache') }
sub syslogdir       { catdir(localstatedir(), 'log') }
sub spooldir        { catdir(localstatedir(), 'spool') }
sub rundir          { catdir(localstatedir(), 'run') }
sub lockdir         { catdir(localstatedir(), 'lock') }
sub sharedstatedir  { catdir(localstatedir(), 'lib') }

#
# ��������� ���������� (Core)
#
sub getsyscfg { __PACKAGE__->ext_syscfg(@_) }
sub syscfg { __PACKAGE__->ext_syscfg(@_) }
sub isostype {__PACKAGE__->ext_isostype(@_)}
sub isos {__PACKAGE__->ext_isos(@_)}

#
# ����������� ��������� ������ (API)
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
sub _debug { goto &carp } # ������ ����� ����������
sub _error { goto &carp } # ����� � ����������� ����� STDERROR, ������ ��� ��������� �������!!!
sub _exception { goto &confess } # ����� � ����������� ����� STDERROR � �������, ������ ��� ��������� �������!!!
1;

package  # hide me from PAUSE
    CTK::Util::SysConfig;
use strict;
use vars qw/$VERSION/;
$VERSION = $CTK::Util::VERSION;
use Config qw//;
use Perl::OSType qw//;
sub ext_syscfg {
    # ��������� �������� ��������� ������������
    my $caller; $caller = shift if (@_ && $_[0] && $_[0] eq 'CTK::Util');
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my $param = shift;
    if (defined $param) {
        return $Config::Config{$param}
    }
    my %locconf = %Config::Config;
    return %locconf;
}
sub ext_isostype {
    # ��������� ���� ������������ ������ � �������, ���� ��� ������������� ��������, �� TRUE
    my $caller; $caller = shift if (@_ && $_[0] && $_[0] eq 'CTK::Util');
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    return Perl::OSType::is_os_type(@_);
}
sub ext_isos {
    # ��������� ����� ������������ ������ � �������, ���� ����� ��� ������������� ��������, �� TRUE
    my $caller; $caller = shift if (@_ && $_[0] && $_[0] eq 'CTK::Util');
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    my $cos = shift;
    my $os = $^O;
    return $cos && (lc($os) eq lc($cos)) && Perl::OSType::os_type($os) ? 1 : 0;
}
1;


__END__