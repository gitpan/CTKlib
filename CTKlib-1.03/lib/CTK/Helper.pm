package CTK::Helper;
#
# Процедуры возвращающие контенты файлов-скриптов. новых проектов
# Для обработки ключей %PROJECTNAME% и %PODSIG% нужно использовать регулярные выражения
#
# %PODSIG%      -- знак "=" (равно)
# %PROJECTNAME% -- имя проекта в Unix стиле
#
use vars qw/$VERSION/;
$VERSION = q/$Revision: 53 $/ =~ /(\d+\.?\d*)/ ? $1 : '1.00';

use base qw/Exporter/;
our @EXPORT = qw(
        get_projectcontent
        get_projectcontent_inc
        get_projectcontent_tiny
        get_projectcontent_conf
    );

sub get_projectcontent {return <<'CONTENT';
#!/usr/bin/perl -w
use strict;

%PODSIG%head1 NAME

%PROJECTNAME%.pl - blah-blah-blah

%PODSIG%head1 VERSION

Version 1.00

%PODSIG%head1 SYNOPSIS

    %PROJECTNAME%.pl [options] [commands [args]] 

    %PROJECTNAME%.pl [-lcdt]

    %PROJECTNAME%.pl [-h | -v | -m]

    %PROJECTNAME%.pl [--help | --version | --man]
    
    %PROJECTNAME%.pl [[--debug | --nodebug] [--log | --nolog] [--logclear] [--testmode | --notestmode]]
           [ test | void ]

%PODSIG%head1 OPTIONS

%PODSIG%over 4

%PODSIG%item B<-d, --debug>

Включение отладочного режима. 
Для управления уровнем отладки см. параметр DEBUG секции кофигурирования.
Отладочный режим позволяет видеть процесс работы на экране терминала

%PODSIG%item B<--nodebug>

Выключение отладочного режима (default).
Для управлением уровнем отладки см. параметр DEBUG секции кофигурирования 

%PODSIG%item B<-h, --help>

Отображение краткой справочной информации

%PODSIG%item B<-v, --ver, --version>

Отображение текущей версии и наименование программы

%PODSIG%item B<-m, --man>

Отображение полной справочной документации

%PODSIG%item B<-l, --log>

Включение режима записи в лог.
Для управлением уровнем записи в лог см. параметр LOG секции кофигурирования.

%PODSIG%item B<--nolog>

Выключение режима записи в лог (default)

%PODSIG%item B<-c, --logclear>

Очищать лог файл при каждом запуске программы

%PODSIG%item B<--signature=MESSAGE>

Помечать подписью каждую строчку лога

%PODSIG%item B<-t, --testmode>

Включение тестового режима.
Для управления уровнем тестового режима см. параметр TESTMODE секции кофигурирования.

%PODSIG%item B<--notestmode>

Выключение тестового режима (default)

%PODSIG%back

%PODSIG%head1 COMMANDS

%PODSIG%over 4

%PODSIG%item B<test>

Тестирование всех основных компонентов робота

%PODSIG%item B<void>

Временные операции, по умолчанию пустой контекст, запускается и ничего не делает

%PODSIG%back

%PODSIG%head1 DESCRIPTION

blah-blah-blah

%PODSIG%head1 HISTORY

%PODSIG%over 8

%PODSIG%item B<1.00 / %GMT%>

Init version

%PODSIG%back

%PODSIG%head1 DEPENDENCIES

L<Moose>

%PODSIG%head1 AUTHOR

Yor Name E<lt>your@email.comE<gt>

%PODSIG%head1 TO DO

%PODSIG%head1 BUGS

%PODSIG%head1 SEE ALSO

C<perl>, C<Moose>

%PODSIG%head1 DIAGNOSTICS

The usual warnings if it can't read or write the files involved.

%PODSIG%head1 COPYRIGHT

Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

%PODSIG%head1 LICENSE

This program is distributed under the GNU GPL v3.

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

%PODSIG%cut

use constant {
    PIDFILE   => '%PROJECTNAME%.pid', # Файл PID по умолчанию

    # Команды и их параметры.
    CMDDEFAULT => '',
    CMD => {
        void => {
            pidcheck => 0, # 0 - OFF, 1 - ON
        },
        test => {
            pidcheck => 1, # 0 - OFF, 1 - ON
            foo      => 'qwerty',
            bar      => [],
        },
    },

};

use Getopt::Long;
use Pod::Usage;
use FindBin qw($RealBin);

# Others:
use Data::Dumper;

# CTK Packages
use lib "$RealBin/inc";
use base '%PROJECTNAME%';
use CTK;
use CTK::FilePid;

# Режимы команд
Getopt::Long::Configure ("bundling");

GetOptions(\%OPT, @OPTSYSDEF, # humvdlcyt?

    # Параметры Вашей программы
    "foo|f=s",            # FOO
    "bar|b=i",            # BAR
    "baz|z=s",            # BAZ
    
) || pod2usage(-exitval => 1, -verbose => 0, -output => \*CTK::CTKCP);
pod2usage(-exitval => 0, -verbose => 0, -output => \*CTK::CTKCP) if $OPT{help};
pod2usage(-exitval => 0, -verbose => 99, -sections => 'NAME|VERSION', -output => \*CTK::CTKCP) if $OPT{version};
pod2usage(-exitval => 0, -verbose => 2, -output => \*CTK::CTKCP) if $OPT{man};

# VARS
my %cmddata;

# Команды
my $command   = @ARGV ? shift @ARGV : CMDDEFAULT; # Команда
my @arguments = @ARGV ? @ARGV : (); # Аргументы команд
my @commands  = keys %{sub{CMD}->()}; # @{sub{COMMANDS}->()}
pod2usage(-exitval => 1, -verbose => 99, -sections => 'SYNOPSIS|OPTIONS|COMMANDS', -output => \*CTK::CTKCP)
    if ( (grep {$_ eq $command} @commands) ? 0 : 1 );
    
# Preparing directories and Log Clear 
CTK::preparedir({
        logdir  => $LOGDIR,
        datadir => $DATADIR,
    });
unlink( $LOGFILE ) if( $OPT{logclear} && -e $LOGFILE ); # Remove unnesessary log

START:  debug "-"x16, " START ", (testmode() ? 'IN TEST MODE ' : ''), tms," ","-"x16;
#########################
### START
#########################

foreach my $curcmd (@commands) {
    if ($command eq $curcmd) {
        my $code = __PACKAGE__->can(uc($command));
        if ($code && ref($code) eq 'CODE') {
            %cmddata = %{CMD->{$command}};
            $cmddata{arguments} = [@arguments];

            # Определение PID файла и получение состояния
            my $pidfile = new CTK::FilePid({ file => CTK::catfile($DATADIR, $cmddata{pidfile} || PIDFILE) });
            my $pidstat = $pidfile->running || 0;
            
            debug "";
            debug "==== START COMMAND: ".uc($curcmd)." ($$) ====";
            
            if ($cmddata{pidcheck}) {
                exception("PID STATE (".$pidfile->file()."): ALREADY EXISTS (PID: $pidstat)" ) if $pidstat;
                $pidfile->write;
            }

            &{$code}(%cmddata); # Передается в процедуру Хэш данных и параметров
            
            if ($cmddata{pidcheck}) {
                $pidfile->remove;
            }
            
            debug "==== FINISH COMMAND: ".uc($curcmd)." ($$) ====";
        } else {
            exception("Sub \"".uc($command)."\" undefined");
        }
        last;
    }
}

#########################
### FINISH
#########################
FINISH: debug "-"x16, " FINISH ", (testmode() ? 'IN TEST MODE ' : '') ,tms," ","-"x16;
exit(0);

1;
__END__
CONTENT
}
sub get_projectcontent_inc {return <<'CONTENT';
package %PROJECTNAME%;
use strict;

use vars qw/$VERSION/;
$VERSION = 1.00;

use CTK qw/:BASE/;
#use CTK::DBI;

#########################
# КОМАНДЫ (МАКРО)
#########################
sub VOID {
    # Пустой контекст
    debug("VOID CONTEXT");
    1;
}
sub TEST {
    # Тестирование функционала
    debug("Тестирование функционала");
    my %cmd = @_; #debug(join "; ",@{$cmd{arguments}});

    # Строим главный объект
    my $c = new CTK;
    
    #my $config = $c->config;
    #debug(Dumper($config));
    
    # ...
    
    1;
}

1;
__END__
CONTENT
}
sub get_projectcontent_tiny {return <<'CONTENT';
#!/usr/bin/perl -w
use strict;

use CTK;

START:  say "-"x16, " START ", tms," ","-"x16;
#########################
### START
#########################

my $c = new CTK;

#########################
### FINISH
#########################
FINISH: say "-"x16, " FINISH ", tms," ","-"x16;
exit(0);

1;
__END__
CONTENT
}
sub get_projectcontent_conf {return <<'CONTENT';
#
# See Config::General for details
#

<Oracle prod>
    dsn		DBI:Oracle:PROD
    user	login
    password	123
</Oracle>
<Oracle prodt>
    dsn		DBI:Oracle:PRODT
    user	login
    password	123
</Oracle>

# Программа SendMail и параметры отправки почты. Умолчания
<SendMail>
    # Основные данные отправки писем
    to          to@example.com
    cc          cc@example.com
    from        from@example.com
    
    # Адресаты в случает тестирования и ошибок
    testmail    test@example.com
    errormail   error@example.com
    
    # Кодировка письма из которой произойдет перевод в кодировку UTF-8
    charset     windows-1251
    type        text/plain
    
    # Программа sendmail и ее параметры
    sendmail    /usr/sbin/sendmail
    flags       -t
    
    # SMTP сервер, если есть
    smtp        192.168.1.1
    
    # Авторизация SMTP
    #smtpuser user
    #smtppass password
</SendMail>

#######################
#
# Секция работы с архивами
# 
# тут определяются основные настройки работы с архивами
# каждое значение любого параметра обрабатывается единым механизмом обработки маски.
# Ключи могут быть использованы следующие:
#
#    FILE     -- Полное имя файла с путем
#    FILENAME -- Только имя файлов архивов
#    DIRSRC   -- Каталог поиска имен файлов
#    DIRIN    -- = DIRSRC
#    DIRDST   -- Каталог для исзвлечения содержимого архивов
#    DIROUT   -- = DIRDST
#    EXC      -- 'exclude file' Зарезервировано!!!
#    LIST     -- Список файлов через пробел
#
# Для случая сжатия используется следеющий набор ключей:
#    FILE     -- Полное имя выходного файла архива с путем
#    DIRSRC   -- Каталог поиска имен файлов и подкаталогов для сжатия
#    DIRIN    -- DIRSRC
#    EXC      -- 'exclude file' Зарезервировано!!!
#    LIST     -- Список файлов через пробел
#
######################
<Arc tar>
    type       tar
    ext        tar
    create     tar -cpf [FILE] [LIST]
    extract    tar -xpf [FILE] [DIRDST]
    exclude    --exclude-from
    list       tar -tf [FILE]
    nocompress tar -cpf [FILE]
</Arc>
<Arc tgz>
    type       tar
    ext        tgz
    create     tar -zcpf [FILE] [LIST]
    extract    tar -zxpf [FILE] [DIRDST]
    exclude    --exclude-from
    list       tar -ztf [FILE]
    nocompress tar -cpf [FILE]
</Arc>
<Arc gz>
    type       gz
    ext        gz
    create     gzip --best [FILE] [LIST]
    extract    gzip -d [FILE]
    exclude    --exclude-from
    list       gzip -l [FILE]
    nocompress gzip -0 [FILE]
</Arc>
<Arc zip>
    type       zip
    ext        zip
    # Win
    #create    zip -rqq [FILE] [LIST]
    create     zip -rqqy [FILE] [LIST]
    # Win
    #extract   unzip -uqqoX [FILE] -d [DIRDST]
    extract    unzip -uqqoX [FILE] [DIRDST]
    exclude    -x\@
    list       unzip -lqq
    nocompress zip -qq0
</Arc>
<Arc rar>
    type       rar
    ext        rar
    # Win
    #create    rar a -r -y -ep2 [FILE] [LIST]
    create     rar a -r -ol -y [FILE] [LIST]
    extract    rar x -y [FILE] [DIRDST]
    exclude    -x\@
    list       rar vb
    nocompress rar a -m0
</Arc>

Include conf/*.conf
CONTENT
}
1;
__END__
