package CTK; # $Revision: 31 $
use Moose; #use strict;

=head1 NAME

CTK - Command-line ToolKit library (CTKlib)

=head1 VERSION

Version 1.00

$Id: CTK.pm 31 2012-11-21 07:23:06Z minus $

=head1 SYNOPSIS

  use CTK;
  use CTK (
        prefix     => 'myprogram',
        suffix     => 'sample',
        cfgfile    => ...path to conf file... ,
        voidfile   => ...path to void file... ,
        needconfig => 1, # need create conf file
    );
  
=head1 ABSTRACT

CTKlib - Command-line ToolKit library (CTKlib). Command line interface (CLI)

=head1 DESCRIPTION

Sorry. Detail manual is preparing now and it will be available later

* See L<README> file

=head1 HISTORY

=over 8

=item B<1.00 / 18.06.2012>

Init version

=back

See L<CHANGES> file for details

=head1 DEPENDENCIES

L<ExtUtils::MakeMaker>,
L<File::Spec>,
L<Test::More>,
L<Config::General>,
L<Time::Local>,
L<MIME::Base64>,
L<MIME::Lite>,
L<Net::FTP>,
L<File::Path>,
L<IPC::Open3>,
L<Term::ReadKey>,
L<IO::Handle>,
L<File::Copy>,
L<Archive::Tar>,
L<Archive::Zip>,
L<Archive::Extract>,
L<Moose>,
L<namespace::autoclean>,
L<URI>,
L<LWP>,
L<LWP::MediaTypes>,
L<LWP::UserAgent>,
L<HTTP::Headers>,
L<HTTP::Request>,
L<HTTP::Response>

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>.

=head1 TO DO

* See L<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<Moose>

=head1 DIAGNOSTICS

The usual warnings if it can't read or write the files involved.

=head1 COPYRIGHT

Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See L<LICENSE> file

=cut
use vars qw/
        $VERSION
        $TM $EXEDIR $DATADIR $CONFDIR $CONFFILE $LOGDIR $LOGFILE %ARGS %OPT @OPTSYSDEF
    /;
$VERSION = '1.00';

use constant {
    DEBUG     => 1, # 0 - off, 1 - on, 2 - all (+ http headers and other)
    LOG       => 1, # 0 - off, 1 - on
    TESTMODE  => 1, # 0 - off, 1 - on (�������� ����� ����������� ������ �� �������� ���� � �������� ������)

    WIN       => $^O =~ /mswin/i ? 1 : 0,
    NULL      => $^O =~ /mswin/i ? 'NUL' : '/dev/null',
    TONULL    => $^O =~ /mswin/i ? '>NUL 2>&1' : '>/dev/null 2>&1',
    ERR2OUT   => '2>&1',
    
    TERMCHSET => 'utf8', # ��������� ��������� ��� ���������������
    
    VOIDFILE  => 'void.txt', # ���� VOID (��� ������������ ������ � �������)
    CFGFILED  => 'ctklib.conf', # ���� ������������ �� ���������
    CFGFILE   => '[PREFIX].conf', # ���� ������������
};

use base qw /Exporter CTK::CLI CTK::Net CTK::File CTK::Arc CTK::Crypt/; # extends qw/CTK::Arc/;
our @EXPORT = qw(
        say debug tms exception testmode debugmode logmode
        $EXEDIR $DATADIR $CONFDIR $CONFFILE $LOGDIR $LOGFILE %OPT @OPTSYSDEF
    );
our @EXPORT_OK = qw(
        say debug tms exception testmode debugmode logmode
        $TM $EXEDIR $DATADIR $CONFDIR $CONFFILE $LOGDIR $LOGFILE %OPT @OPTSYSDEF
    );
our %EXPORT_TAGS = (
        ALL     => [qw($TM $EXEDIR $DATADIR $CONFDIR $CONFFILE $LOGDIR $LOGFILE %OPT @OPTSYSDEF say debug tms exception testmode debugmode logmode)],
        BASE    => [qw($EXEDIR $DATADIR $CONFDIR $LOGDIR say debug tms exception testmode debugmode logmode)],
        FUNC    => [qw(say debug tms exception testmode debugmode logmode)],
        FUNCS   => [qw(say debug tms exception testmode debugmode logmode)],
        SUB     => [qw(say debug tms exception testmode debugmode logmode)],
        SUBS    => [qw(say debug tms exception testmode debugmode logmode)],
        VARS    => [qw($TM $EXEDIR $DATADIR $CONFDIR $CONFFILE $LOGDIR $LOGFILE %OPT @OPTSYSDEF)],
    );
    
use Time::HiRes qw(gettimeofday);
use FindBin qw($RealBin $Script);

use Config::General;
use CTK::CPX;
use CTK::Util;

########################
## ������� �������������
########################
sub init {
    # GLOBAL VARS
    $TM       = gettimeofday();
    $EXEDIR   = $RealBin; # ������� ��� ������
    $DATADIR  = catfile($EXEDIR,"data"); # ����� ��� �������� ������ � ������
    $CONFDIR  = catfile($EXEDIR,"conf"); # ����� ��� �������� ���������������� �����
    $CONFFILE = catfile($EXEDIR,CFGFILED); # ��� ��� ������������ ����� (���������). ��. BUILD()
    $LOGDIR   = catfile($EXEDIR,"log"); # ����� ��� �������� ������ � ������
    $LOGFILE  = catfile($LOGDIR,"ctklib.log"); # ��� ��� ���� �����
    %OPT = (
        debug     => DEBUG    ? 0 : 1, 
        log       => LOG      ? 0 : 1,
        testmode  => TESTMODE ? 0 : 1,
    );
    @OPTSYSDEF = ( # ��������� �� ���������. ������������ �������� �����: humvdlcyt?
        # ��������� �������
        "help|usage|h|u|?",                  # ������ �� ���������
        "man|m",                             # �������
        "version|ver|v",                     # ������� ������
    
        # ��������� �������
        "debug|d!",                          # ������� (+ no~) -- �� �����, ������� ������� ��. DEBUG
        "log|l!",                            # ����������� (+ no~) -- � ���, ������� ���� ��. LOG
        "logclear|logclean|clean|clear|c",   # ������� ���� ����� ������ ��������
        "signature|sign|msg|y=s",            # ������� � ����
    
        # ����� ������
        "testmode|test|t!",                  # �������� ����� ������ (+ no~) -- ������� ������ ��. TESTMODE
    );
}    
BEGIN { init() }
*again = \&init;

# ���������� ������������ ������ 
if (WIN) {
    tie *CTKCP, 'CTK::CPX', 'cp866'
} else {
    if (TERMCHSET) { tie *CTKCP, 'CTK::CPX', TERMCHSET } else { *CTKCP = *STDOUT }
}    

########################
## ������� �������
########################
sub say { print CTKCP @_ ? @_ : '',"\n"}
sub debug { 
    unshift(@_,$OPT{signature}." ") if defined $OPT{signature};
    if (LOG && $OPT{log}) {
        my @dt=localtime(time());
        if (open(FD, ">>", $LOGFILE)) {
            flock FD, 2 or carp("Can't lock file: $!");
            print FD sprintf("[%02d.%02d.%04d %02d:%02d:%02d] ",$dt[3],$dt[4]+1,$dt[5]+1900,$dt[2],$dt[1],$dt[0]), @_ ? @_ : '', "\n"; 
            close(FD);
        } else {
            carp("Can't open file to write: $!"); 
        }
    }
    return 1 unless DEBUG && $OPT{debug};
    say(@_);
}
sub tms { "[$$] {TimeStamp: ".sprintf("%+.*f",4, gettimeofday()-$TM)." sec}" }
sub exception { 
    my $clr = " [ CALLER: ".join("; ", caller())." ]"; 
    debug(@_,$clr); 
    confess(translate(join("",(@_,$clr))));
}
sub testmode { return CTK::TESTMODE && $OPT{testmode} } # ���������� ������ TESTMODE ��� ������!
sub debugmode { return (CTK::DEBUG && $OPT{debug}) ? DEBUG : undef } # ���������� ������ DEBUG!
sub logmode { return CTK::LOG && $OPT{log} } # ���������� ������ LOG ��� ������!

########################
## �������� ������ Moose
########################

has 'script'   => (is => 'ro', isa => 'Str', default => $Script);
has 'prefix'   => (is => 'rw', isa => 'Str', default => ($Script =~ /^(.+?)\./ ? $1 : $Script));
has 'suffix'   => (is => 'rw', isa => 'Str', default => '');
has 'cfgfile'  => (is => 'rw', isa => 'Str', default => CFGFILE);
has 'voidfile' => (is => 'rw', isa => 'Str', default => VOIDFILE);
has 'config'   => (is => 'rw', isa => 'HashRef'); # ���������������� ��� (Config::General)
has 'options'  => (is => 'rw', isa => 'HashRef', default => sub { \%OPT } ); # ��� ����� ��������� ������ (Getopt::Long)
has 'needconfig' => (is => 'rw', isa => 'Bool', default => 0); # ����� �� ��������� ������ ������?

sub BUILD { # new
    my $self = shift;
    my $options = shift || {};
    
    # �������� ����-���������
    my $prefix = $self->prefix();
    my $suffix = $self->suffix();
    
    # ����������� �� ������ � ������ ���� ������ �� ����� ������������
    my $oldcfgfile = $self->cfgfile();
    $self->cfgfile(dformat($oldcfgfile,{ # CFGFILE
            PREFIX   => $prefix,
            SUFFIX   => $suffix,
            EXT      => 'conf',
            DEFAULT  => CFGFILED,
        }));
    $self->voidfile(dformat($self->voidfile(),{ # VOIDFILE
            PREFIX   => $prefix,
            SUFFIX   => $suffix,
            EXT      => 'txt',
            DEFAULT  => VOIDFILE,
        }));

    
    # ���������� ������������
    if ($oldcfgfile eq CFGFILE) {
        $CONFFILE = catfile($EXEDIR,$self->cfgfile()); # ��� ��� ������������ �����
    } else {
        $CONFFILE = $self->cfgfile(); # ��������� �������, ������ �� ������ ����� !!
    }
    $self->config({_loadconfig($CONFFILE, $self->needconfig())});
        
    #debug Dumper(\@_);
    return 1;
};

sub AUTOLOAD {
    # ��� ������ ���� ��������� �� ���� �������� ����� ��������� ������
    # ���� ������ ������ �� ��������, �� ������ �������� ������ 
    my $self = shift;
    our $AUTOLOAD;
    my $AL = $AUTOLOAD;
    my $ss = undef;
    $ss = $1 if $AL=~/\:\:([^\:]+)$/;
    if ($ss) {
        #debug($self->x());
        #debug($ss);
        my $lcode = __PACKAGE__->can($ss);
        if ($lcode && ref($lcode) eq 'CODE') {
            &{$lcode}(@_);
        } else {
            exception("Can't call method or procedure \"$ss\"!");
        }
    } else {
        exception("Can't find procedure \"$AL\"!");
    }
    return;    
}
sub DEMOLISH { # DESTROY
    # ������ ����������
}

########################
## ���������� ���������
########################
sub _loadconfig {
    # ������ ����������������� ����� ��� �������� �������
    my $cfile = shift || '';
    my $need  = shift || 0;

    my %config = (loadstatus => 0);
    my $conf;
    
    # �������� ��������� ���������������� ������
    if ($cfile && -e $cfile) {
        $conf = new Config::General( 
                -ConfigFile         => $cfile, 
                -ConfigPath         => [$EXEDIR, $CONFDIR],
                -ApacheCompatible   => 1,
                -LowerCaseNames     => 1,
                -AutoTrue           => 1,
            );
        %config = $conf->getall;
        $config{configfiles} = [$conf->files];
        $config{loadstatus} = 1;
    }
    
    # ������������ ���� ������� ��������� ������������
    return %config unless $need;
    
    # ���� �� ������� ���������, �� �������������� ������� �������� ������ ������� (�������)
    unless (%config && $config{loadstatus}) {
        debug "Configuration save into \"$cfile\"...";
        $conf = new Config::General( -ConfigHash => \%config, );
        $conf->save_file($cfile)
    }

    return %config;
}



#
## ��������� ��������� � ������, ��� �������� �� ������ ����� -- ����� �� ��� ���������� ��������
## � ������������ � ������ �����������
##
sub getObj {
    my $self = shift;
    return $self;
}
sub getMeta { # ������� ������ ��������� ������� � ������ ������
    my $meta = __PACKAGE__->meta();
 
    debug "Attributes:";
    for my $attribute ( $meta->get_all_attributes ) {
        debug " ", $attribute->name();
 
        if ( $attribute->has_type_constraint ) {
            debug "  type: ", $attribute->type_constraint->name;
        }
    }
 
    debug;
    debug "Methodts:";
    for my $method ( sort {$a->package_name().$a->name() cmp $b->package_name().$b->name()} $meta->get_all_methods ) {
        debug(" ", $method->package_name, " :: ", $method->name);
    }
    
    return $meta;
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;

__END__
