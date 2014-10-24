package CTK; # $Id: CTK.pm 71 2012-12-28 22:11:58Z minus $
use Moose; #use strict;

=head1 NAME

CTK - Command-line ToolKit

=head1 VERSION

Version 1.06

=head1 REVISION

$Revision: 71 $

=head1 SYNOPSIS

    use CTK;
  
    use CTK qw( :BASE ); # :SUBS and :VARS tags to export
  
    use CTK qw( :SUBS ); # :SUBS tag only to export
  
    use CTK qw( :VARS ); # :VARS tag only to export
  
    my $c = new CTK;
  
    my $c = new CTK (
        prefix       => 'myprogram',
        suffix       => 'sample',
        cfgfile      => '/path/to/conf/file.conf',
        voidfile     => '/path/to/void/file.txt',
        needconfig   => 1, # need creating empty config file
        loglevel     => 'info', # or '1'
        logfile      => CTK::catfile($LOGDIR,'foo.log'),
        logseparator => ' ', # as default
    );
  
=head1 ABSTRACT

CTKlib - Command-line ToolKit library (CTKlib). Command line interface (CLI)

=head1 DESCRIPTION

Sorry. Detail manual is preparing now and it will be available later

See C<README> file

=head1 HISTORY

=over 8

=item B<1.00 / 18.06.2012>

Init version

=back

See C<CHANGES> file for details

=head1 DEPENDENCIES

L<Archive::Extract>,
L<Archive::Tar>,
L<Archive::Zip>,
L<Config::General>,
L<DBI>,
L<ExtUtils::MakeMaker>,
L<File::Copy>,
L<File::Path>,
L<File::Pid>,
L<File::Spec>,
L<HTTP::Headers>,
L<HTTP::Request>,
L<HTTP::Response>,
L<IO::Handle>,
L<IPC::Open3>,
L<LWP>,
L<LWP::MediaTypes>,
L<LWP::UserAgent>,
L<MIME::Base64>,
L<MIME::Lite>,
L<Moose>,
L<namespace::autoclean>,
L<Net::FTP>,
L<Sys::SigAction>,
L<Term::ReadKey>,
L<Term::ReadLine>,
L<Test::More>,
L<Text::ParseWords>,
L<Time::Local>,
L<Time::HiRes>,
L<URI>,
L<YAML>

=head1 TO DO

See C<TODO> file

=head1 BUGS

* none noted

=head1 SEE ALSO

C<perl>, L<Moose>

=head1 DIAGNOSTICS

The usual warnings if it can't read or write the files involved.

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut
use vars qw/
        $VERSION
        $TM $EXEDIR $DATADIR $CONFDIR $CONFFILE $LOGDIR $LOGFILE %ARGS %OPT @OPTSYSDEF
    /;
$VERSION = 1.06;

use constant {
    DEBUG     => 1, # 0 - off, 1 - on, 2 - all (+ http headers and other)
    LOG       => 1, # 0 - off, 1 - on
    TESTMODE  => 1, # 0 - off, 1 - on (�������� ����� ����������� ������ �� �������� ���� � �������� ������)

    WIN       => $^O =~ /mswin/i ? 1 : 0,
    NULL      => $^O =~ /mswin/i ? 'NUL' : '/dev/null',
    TONULL    => $^O =~ /mswin/i ? '>NUL 2>&1' : '>/dev/null 2>&1',
    ERR2OUT   => '2>&1',
    
    TERMCHSET => 'utf8', # ��������� ��������� ��� ���������������
    
    LOGFILED  => 'ctklib.log',    # ���� ���� �� ���������
    CFGFILED  => 'ctklib.conf',   # ���� ������������ �� ���������
    CFGFILE   => '[PREFIX].conf', # ���� ������������
    VOIDFILE  => 'void.txt',      # ���� VOID (��� ������������ ������ � �������)
    
    DATADIRD  => 'data', # ��� �������� ������ �� ���������
    CONFDIRD  => 'conf', # ��� �������� ������������ �� ���������
    LOGDIRD   => 'log',  # ��� �������� ����� �� ���������
};

use base qw /Exporter/; # extends qw/CTK::Arc/;
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
        NONE    => [qw()],
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
    $EXEDIR   = $RealBin; # ������� ��� ������ (�� ��������������)
    $DATADIR  = catfile($EXEDIR, DATADIRD); # ����� ��� �������� ������ � ������
    $CONFDIR  = catfile($EXEDIR, CONFDIRD); # ����� ��� �������� ���������������� ����� (�� �������)
    $LOGDIR   = catfile($EXEDIR, LOGDIRD);  # ����� ��� �������� ������ � ������
    $CONFFILE = catfile($EXEDIR, CFGFILED); # ���� ������������ (���������). ��. BUILD()
    $LOGFILE  = catfile($LOGDIR, LOGFILED); # ���� ����
    %OPT = (                                # ����� ��������� ������
        'debug'     => DEBUG    ? 0 : 1, 
        'log'       => LOG      ? 0 : 1,
        'testmode'  => TESTMODE ? 0 : 1,
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
    if (LOG && $OPT{'log'}) {
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
sub logmode { return CTK::LOG && $OPT{'log'} } # ���������� ������ LOG ��� ������!

########################
## �������� ������ Moose
########################

with 'CTK::CLI' => {
            -excludes => [qw/_cli_select/],
        },
     'CTK::File' => { 
            -excludes => [qw/_error/], 
        },
     'CTK::Crypt' => {},
     'CTK::Arc' => {
            -excludes => [qw/_getarc/],
        },
     'CTK::Net' => {
            -alias    => {
                    _debug_http => 'debug_http',
                },
            -excludes => [qw/_error/], 
        },
     'CTK::Log' => { 
            -excludes => [qw/_flush/], 
        };

has 'revision'  => ( # �������
        is      => 'ro',
        isa     => 'Str',
        default => q/$Revision: 71 $/ =~ /(\d+\.?\d*)/ ? $1 : '0',
        lazy    => 1,
        init_arg=> undef,
    );
has 'script'    => ( # ��� �������
        is      => 'ro', 
        isa     => 'Str', 
        default => $Script,
    );
has 'prefix'    => ( # ������� (��� ���� �������� �� ���� CTKlib)
        is      => 'rw', 
        isa     => 'Str', 
        default => ($Script =~ /^(.+?)\./ ? $1 : $Script),
    );
has 'suffix'    => ( # ������ (��� ���� �������� �� ���� CTKlib)
        is      => 'rw', 
        isa     => 'Str', 
        default => '',
    );
has 'cfgfile'   => ( # ������ ��� ����� ������������
        is      => 'rw', 
        isa     => 'Str', 
        default => CFGFILE,
        trigger => sub {
                my $self = shift;
                my $val = shift || '';
                my $old_val = shift || '';
                #debug "TRIGGER: $self, $val, $old_val";
                $self->{cfgfile} = dformat($val,{ 
                        PREFIX   => $self->prefix(),
                        SUFFIX   => $self->suffix(),
                        EXT      => 'conf',
                        DEFAULT  => CFGFILED,
                    }) if $val;
                $CONFFILE = $self->{cfgfile};
            },
    );
has 'voidfile'  => ( # ������ ��� ����� ������� �����, ��� ���� ������
        is      => 'rw', 
        isa     => 'Str', 
        default => VOIDFILE,
        trigger => sub {
                my $self = shift;
                my $val = shift || '';
                my $old_val = shift || '';
                # debug "TRIGGER: $self, $val, $old_val";
                $self->{voidfile} = dformat($val,{ 
                        PREFIX   => $self->prefix(),
                        SUFFIX   => $self->suffix(),
                        EXT      => 'txt',
                        DEFAULT  => VOIDFILE,
                    }) if $val; # if $val ne $old_val
            },
    );
has 'config'    => ( # ���������������� ��� (Config::General)
        is      => 'rw', 
        isa     => 'HashRef',
    ); 
has 'options'   => ( # ��� ����� ��������� ������ (Getopt::Long)
        is      => 'rw', 
        isa     => 'HashRef', 
        default => sub { \%OPT } ,
    ); 
has 'needconfig'=> ( # ����� �� ��������� ������ ������ � ������ ���������� �������?
        is      => 'rw', 
        isa     => 'Bool', 
        default => 0,
    ); 
has 'exedir'    => ( # ������� �������� ����������� ��������� ���������� ����������
        is      => 'ro', 
        isa     => 'Str', 
        default => sub { $EXEDIR },
        lazy    => 1,
    );
has 'datadir'   => ( # ������� �������� ����������� ��������� ������� ����������
        is      => 'rw', 
        isa     => 'Str', 
        default => sub { $DATADIR },
        lazy    => 1,
        trigger => sub {
                my $self = shift;
                my $val = shift || '';
                # debug "TRIGGER: $self, $val";
                $DATADIR = $val;
            },
        
    );
has 'confdir'   => ( # ������� �������� ����������� ��������� ���������� ���������������� ������
        is      => 'rw', 
        isa     => 'Str', 
        default => sub { $CONFDIR },
        lazy    => 1,
        trigger => sub {
                my $self = shift;
                my $val = shift || '';
                # debug "TRIGGER: $self, $val";
                $CONFDIR = $val;
            },

    );
has 'logdir'    => ( # ������� �������� ����������� ��������� ���������� �����
        is      => 'rw', 
        isa     => 'Str', 
        default => sub { $LOGDIR },
        lazy    => 1,
        trigger => sub {
                my $self = shift;
                my $val = shift || '';
                # debug "TRIGGER: $self, $val";
                $LOGDIR = $val;
            },

    );
    
sub BUILD { # new
    my $self = shift;
    my $options = shift || {};
    
    # �������� ����-���������
    my $prefix = $self->prefix();
    my $suffix = $self->suffix();
    
    # ����������� �� ������ � ������ ���� ������ �� ����� ������������
    my $oldcfgfile = $self->cfgfile();
    $oldcfgfile = ($oldcfgfile eq CFGFILE) ? catfile($EXEDIR,$self->cfgfile()) : $self->cfgfile();
    $self->cfgfile($oldcfgfile); # CFGFILE rebuilding
    $self->voidfile($self->voidfile()); # VOIDFILE rebuilding
    
    # ���������� ����� ������������
    $self->config({_loadconfig($self->cfgfile(), $self->needconfig())});
        
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
