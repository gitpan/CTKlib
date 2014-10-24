package CTK::Helper; # $Id: Helper.pm 99 2013-02-01 08:29:00Z minus $
#
# ��������� ������������ �������� ������-��������. ����� ��������
# ��� ��������� ������ %PROJECTNAME% � %PODSIG% ����� ������������ ���������� ���������
#
# %PODSIG%      -- ���� "=" (�����)
# %PROJECTNAME% -- ��� ������� � Unix �����
#
use vars qw/$VERSION/;
$VERSION = q/$Revision: 99 $/ =~ /(\d+\.?\d*)/ ? sprintf("%.2f",($1+100)/100) : '1.00';

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
    
    %PROJECTNAME%.pl [--log] [--logclear] [--debug] [--testmode] [--signature=MESSAGE]
           [ test | void ]

%PODSIG%head1 OPTIONS

%PODSIG%over 4

%PODSIG%item B<-c, --logclear>

������� ���� ���������� ���� CTK ��� ������ ������ ���������.

%PODSIG%item B<-d, --debug>

��������� ���������� ����������� ������ ������ ������ CTK.
���������� ����� ��������� ������ ������� ������ ��������� �� ������ ���������.

%PODSIG%item B<-h, --help>

����������� ������� ���������� ����������.

%PODSIG%item B<-l, --log>

��������� ������ ������ ���������� (debug) ���������� � ��������� ��� CTK.

%PODSIG%item B<-m, --man>

����������� ������ ���������� ����������.

%PODSIG%item B<--signature=MESSAGE>

�������� �������� ������ ������� ���������� ���� CTK ���������� MESSAGE.

%PODSIG%item B<-t, --testmode>

��������� ��������� ������ ������ ���������.

%PODSIG%item B<-v, --ver, --version>

����������� ������� ������ � ������������ ���������.

%PODSIG%back

%PODSIG%head1 COMMANDS

%PODSIG%over 4

%PODSIG%item B<test>

������������ ���� �������� ����������� ���������.

%PODSIG%item B<void>

������ ��������, ��������� ����������� � ������ �� ������.

%PODSIG%back

%PODSIG%head1 DESCRIPTION

blah-blah-blah

%PODSIG%head1 HISTORY

%PODSIG%over 8

%PODSIG%item B<1.00 / %GMT%>

Init version

%PODSIG%back

%PODSIG%head1 DEPENDENCIES

L<CTK>

%PODSIG%head1 AUTHOR

Your Name E<lt>your@email.comE<gt>

%PODSIG%head1 TO DO

%PODSIG%head1 BUGS

%PODSIG%head1 SEE ALSO

C<perl>, L<CTK>

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
    PIDFILE   => '%PROJECTNAME%.pid', # ���� PID �� ���������

    # ������� � �� ���������.
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
# use Data::Dumper;

# CTK Packages
use lib "$RealBin/inc";
use base '%PROJECTNAME%';
use CTK;
use CTK::FilePid;

# ������ ������
Getopt::Long::Configure ("bundling");

GetOptions(\%OPT, @OPTSYSDEF, # humvdlcyt?

    # ��������� ����� ���������
    "foo|f=s",            # FOO
    "bar|b=i",            # BAR
    "baz|z=s",            # BAZ
    
) || pod2usage(-exitval => 1, -verbose => 0, -output => \*CTK::CTKCP);
pod2usage(-exitval => 0, -verbose => 0, -output => \*CTK::CTKCP) if $OPT{help};
pod2usage(-exitval => 0, -verbose => 99, -sections => 'NAME|VERSION', -output => \*CTK::CTKCP) if $OPT{version};
pod2usage(-exitval => 0, -verbose => 2, -output => \*CTK::CTKCP) if $OPT{man};

# VARS
my %cmddata;

# �������
my $command   = @ARGV ? shift @ARGV : CMDDEFAULT; # �������
my @arguments = @ARGV ? @ARGV : (); # ��������� ������
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

my $code = __PACKAGE__->can(uc($command));
if ($code && ref($code) eq 'CODE') {
    %cmddata = %{CMD->{$command}};
    $cmddata{arguments} = [@arguments];

    # ����������� PID ����� � ��������� ���������
    my $pidfile = new CTK::FilePid({ file => CTK::catfile($DATADIR, $cmddata{pidfile} || PIDFILE) });
    my $pidstat = $pidfile->running || 0;
    
    debug "==== START COMMAND: ".uc($command)." ($$) ====";
    
    if ($cmddata{pidcheck}) {
        exception("PID STATE (".$pidfile->file()."): ALREADY EXISTS (PID: $pidstat)" ) if $pidstat;
        $pidfile->write;
    }

    &{$code}(%cmddata); # ���������� � ��������� ��� ������ � ����������
    
    if ($cmddata{pidcheck}) {
        $pidfile->remove;
    }
    
    debug "==== FINISH COMMAND: ".uc($command)." ($$) ====";
} else {
    exception("Sub \"".uc($command)."\" undefined");
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
# ������� (�����)
#########################
sub VOID {
    # ������ ��������
    debug("VOID CONTEXT");
    1;
}
sub TEST {
    # ������������ �����������
    debug("������������ �����������");
    my %cmd = @_; #debug(join "; ",@{$cmd{arguments}});

    # ������ ������� ������
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

#######################
#
# ������ ������ � ���������� sendmail � �� ����������� �������� �����
#
########################

<SendMail>
    # �������� ������ �������� �����
    to          to@example.com
    cc          cc@example.com
    from        from@example.com
    
    # �������� � ������� ������������ � ������
    testmail    test@example.com
    errormail   error@example.com
    
    # ��������� ������ �� ������� ���������� ������� � ��������� UTF-8
    charset     windows-1251
    type        text/plain
    
    # ��������� sendmail � �� ���������
    sendmail    /usr/sbin/sendmail
    flags       -t
    
    # SMTP ������, ���� ����. 
    # SMTP ������ �������� ������������ ������������ ��������� sendmail
    smtp        192.168.1.1
    
    # ����������� SMTP
    #smtpuser user
    #smtppass password
</SendMail>

#######################
#
# ������ ������ � ��������. �������� ��. � ������ CTK
# 
# � ���� ������ ������������ �������� ��������� ������ � ��������,
# ������ �������� ������ ��������� �������������� ������ ���������� ��������� �����.
# ����� � ����� ����� ���� ������������ ���������:
#
# ��� ������ ���������� ������ �� �����:
#    FILE     -- ������ ��� ����� � �����
#    FILENAME -- ������ ��� ������ �������
#    DIRSRC   -- ������� ������ ���� ������
#    DIRIN    -- = DIRSRC
#    DIRDST   -- ������� ��� ����������� ����������� �������
#    DIROUT   -- = DIRDST
#    LIST     -- ������ ������ � ������, ����� ������
#    EXC      -- 'exclude file' !!!���������������!!!
#
# ��� ������ ������ ������ ������������ ��������� ����� ������:
#    FILE     -- ������ ��� ��������� ����� ������ � �����
#    DIRSRC   -- ������� ������ ���� ������ � ������������ ��� ������
#    DIRIN    -- = DIRSRC
#    LIST     -- ������ ������ ��� ������, ����� ������
#    EXC      -- 'exclude file' !!!���������������!!!
#
# ��� ������� ����� ����������� ������ � ����������� tar
# 
# <Arc tgz> # ������ ����������� ������. ���, ��� �������, ��� ���������� ������ ������
#    type       tar                       # ��� ������, ��� ������ �����
#    ext        tgz                       # ���������� ������ ������
#    create     tar -zcpf [FILE] [LIST]   # ������� ��� �������� ������
#    extract    tar -zxpf [FILE] [DIRDST] # ������� ��� ���������� ������ �� ������
#    exclude    --exclude-from            # !!!���������������!!!
#    list       tar -ztf [FILE]           # ������� ��� ��������� ������ ������ � ������
#    nocompress tar -cpf [FILE]           # ������� ��� �������� ������ ��� ������
# </Arc>
#
######################

# Tape ARchive
<Arc tar>
    type       tar
    ext        tar
    create     tar -cpf [FILE] [LIST]
    extract    tar -xpf [FILE] [DIRDST]
    exclude    --exclude-from
    list       tar -tf [FILE]
    nocompress tar -cpf [FILE]
</Arc>

# Tape ARchive + GNU Zip
<Arc tgz>
    type       tar
    ext        tgz
    create     tar -zcpf [FILE] [LIST]
    extract    tar -zxpf [FILE] [DIRDST]
    exclude    --exclude-from
    list       tar -ztf [FILE]
    nocompress tar -cpf [FILE]
</Arc>

# GNU Zip
<Arc gz>
    type       gz
    ext        gz
    create     gzip --best [FILE] [LIST]
    extract    gzip -d [FILE]
    exclude    --exclude-from
    list       gzip -l [FILE]
    nocompress gzip -0 [FILE] [LIST]
</Arc>

# ZIP
<Arc zip>
    type       zip
    ext        zip
    # Win
    create     zip -rqq [FILE] [LIST]
    #create    zip -rqqy [FILE] [LIST]
    # Win
    extract    unzip -uqqoX [FILE] -d [DIRDST]
    #extract   unzip -uqqoX [FILE] [DIRDST]
    exclude    -x\@
    list       unzip -lqq
    nocompress zip -qq0
</Arc>

# bzip2 
<Arc bz2>
    type       bzip2 
    ext        bz2
    create     bzip2 --best [FILE] [LIST]
    extract    bzip2 -d [FILE]
    exclude    --exclude-from
    list       bzip2 -l [FILE]
    nocompress bzip2 --fast [FILE] [LIST]
</Arc>

# RAR
<Arc rar>
    type       rar
    ext        rar
    # Win
    create     rar a -r -y -ep2 [FILE] [LIST]
    #create    rar a -r -ol -y [FILE] [LIST]
    extract    rar x -y [FILE] [DIRDST]
    exclude    -x\@
    list       rar vb
    nocompress rar a -m0
</Arc>

#######################
#
# ������ ������ � �� �����
#
########################

#<Oracle prod>
#    DSN        DBI:Oracle:PROD
#    User       login
#    Password   password
#</Oracle>

#<Oracle prodt>
#    DSN        DBI:Oracle:PRODT
#    User       login
#    Password   password
#</Oracle>


Include conf/*.conf
CONTENT
}
1;
__END__
