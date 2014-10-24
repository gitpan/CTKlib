################################################
#
# Module : CTK::DBI
# Style  : OOP
#
# DATE   : 27.11.2012
#
# ������ � ����� ������ �� ������ ������ DBI. ������ ��������� ������ � ������ � ��������� ����
# � ������� multistore � ������� MPMinus
#
# ������ ������� ��������� �������� ������� ���������� ��������: Sys::SigAction
#
# Copyright (c) 1998-2012 D&D Corporation. All rights reserved
# Copyright (C) 1998-2012 Lepenkov Sergej (Serz Minus) <minus@mail333.com>
#
# Version: $Id: DBI.pm 38 2012-11-27 10:16:36Z minus $
#
################################################

package CTK::DBI;
use strict;

=head1 NAME

CTK::DBI - Database independent interface for CTKlib

=head1 VERSION

1.00

$Id: DBI.pm 38 2012-11-27 10:16:36Z minus $

=head1 SYNOPSIS

    use CTK::DBI;

    # MySQL connect
    my $mso = new CTK::DBI(
            -dsn  => 'DBI:mysql:database=TEST;host=192.168.1.1',
            -user => 'login',
            -pass => 'password',
            #-attr => {},
        );
    
    my $dbh = $mso->connect;
    
    # Table select (as array)
    my @result = $mso->table($sql, @inargs);

    # Table select (as hash)
    my %result = $mso->tableh($key, $sql, @inargs); # $key - primary index field name

    # Record (as array)
    my @result = $mso->record($sql, @inargs);

    # Record (as hash)
    my %result = $mso->recordh($sql, @inargs);

    # Fiels (as scalar)
    my $result = $mso->field($sql, @inargs);

    # SQL
    my $sth = $mso->execute($sql, @inargs);
    ...
    $sth->finish;

=head1 DESCRIPTION

For example: debug($oracle->field("select sysdate() from dual"));

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>.

=head1 COPYRIGHT

Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use CTK::Util qw( :API );

use constant {
    TIMEOUT_CONNECT => 5,  # timeout connect
    TIMEOUT_REQUEST => 60, # timeout request
};

use vars qw($VERSION);
our $VERSION = q/$Revision: 38 $/ =~ /(\d+\.?\d*)/ ? $1 : '1.00';

my $LOAD_SigAction = 0;
eval 'use Sys::SigAction';
my $es = $@;
if ($es) {
    eval '
        package Sys::SigAction;
        sub set_sig_handler($$;$$) { 1 };
        1;
    ';
    _debug("Package Sys::SigAction don't installed! Please install this package") unless CTK::WIN;
} else {
    $LOAD_SigAction = 1;
}


use DBI();

sub new {
    my $class = shift;
    my @in = read_attributes([
          ['DSN','STRING','STR'],
          ['USER','USERNAME','LOGIN'],
          ['PASSWORD','PASS'],
          ['ATTRIBUTES','ATTR','ATTRHASH','PARAMS'],
        ],@_);

    # �������� �������� ����������
    my %args = (
            dsn      => $in[0] || '',
            user     => $in[1] || '',
            password => $in[2] || '',
            attr     => $in[3] || undef,
            dbh      => undef,
        );
    
    # �������������� ���������� 
    $args{dbh} = DBI_CONNECT(@args{qw/dsn user password attr/});

    # ������� ���������
    _debug("--- DBI CONNECT {".$args{dsn}."} ---");
   
    my $self = bless {%args}, $class;
    return $self;
}
sub connect {
    # ���������� �������� ����������� �� ������ ���������� dbh
    my $self = shift;
    return $self->{dbh};
}
sub disconnect {
    # ������������� ��������� ����� �� ����������� DESTROY
    my $self = shift;
    DBI_DISCONNECT ($self->{dbh}) if $self->{dbh};
    # ���������� ���������
    _debug("--- DBI DISCONNECT {".($self->{dsn} || '')."} ---"); # �� ������ �����������
}
sub field {
    my $self = shift;
    DBI_EXECUTE_FIELD($self->{dbh},@_)
}
sub record {
    my $self = shift;
    DBI_EXECUTE_RECORD($self->{dbh},@_)
}
sub recordh {
    my $self = shift;
    DBI_EXECUTE_RECORDH($self->{dbh},@_)
}
sub table {
    my $self = shift;
    DBI_EXECUTE_TABLE($self->{dbh},@_)
}
sub tableh {
    my $self = shift;
    my $key_field = shift; # ����� ������������ (http://search.cpan.org/~timb/DBI-1.607/DBI.pm#fetchall_hashref)
    DBI_EXECUTE_TABLEH($self->{dbh},$key_field,@_)
}
sub execute {
    my $self = shift;
    DBI_EXECUTE($self->{dbh},@_)
}
sub DESTROY {
    my $self = shift;
    #debug ('-> ���������� ���������� � ��������: '.($self || ':('));
    $self->disconnect();
}
sub DBI_CONNECT {
    # ���������� � ����� ������ DBI
    # $dbh = DBI_CONNECT($dsn, $user, $password, $attr)
    # IN:
    #   <DSN>      - DSN
    #   <USER>     - ��� ������������ ��
    #   <PASSWORD> - ������ ������������ ��
    #   <ATTR>     - �������� DBD::* (������ �� ���, ��. ������ ��������)
    # OUT:
    #   $dbh - DataBase Handler Object
    #
    my $db_dsn      = shift || ''; # DSN
    my $db_user     = shift || ''; # ��� ������������ ���� ������
    my $db_password = shift || ''; # ������ ������������ ���� ������
    my $db_attr     = shift || {}; # �������� - �������� {ORACLE_enable_utf8 => 1}

    my $dbh;
    
    my $count_connect     = 1;     # TRUE
    my $count_connect_msg = 'OK';  # TRUE
    eval {
        local $SIG{ALRM} = sub { die "Connecting timeout \"$db_dsn\"" } unless $LOAD_SigAction;
        my $h = Sys::SigAction::set_sig_handler( 'ALRM' ,sub { die "Connecting timeout \"$db_dsn\"" ; } );
        eval {
            alarm(TIMEOUT_CONNECT); #implement 2 second time out
            unless ($dbh = DBI->connect($db_dsn, "$db_user", "$db_password", $db_attr)) {
                $count_connect     = 0; # FALSE
                $count_connect_msg = $DBI::errstr;
            }            
            alarm(0);
        };
        alarm(0);
        die $@ if $@;
    };
    if ( $@ ) {
        # ��� �����
        $count_connect     = 0; # FALSE
        $count_connect_msg = $@;
    } 
    unless ($count_connect) {
        # ��� ����� :(
        _error("[".__PACKAGE__.": Connecting error \"$db_dsn\"] $count_connect_msg");
    }
  
    return $dbh;
}
sub DBI_DISCONNECT {
    # �������� ���������� � ����� ������
    # $rc = DBI_DISCONNECT ($dbh)
    # IN:
    #   $dbh - DataBase Handler Object
    # OUT:
    #   $rc - ������ ��������� RC ��� 0 � ������ �������
    #
    my $dbh = shift || return 0;
    my $rc = $dbh->disconnect;

    return $rc; 
}
sub DBI_EXECUTE_FIELD {
    # ��������� ������������� �������� (����)
    # $result = DBI_EXECUTE_FIELD($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $sql - SQL ������
    #   [@inargs] - ��������� ��� ��������
    # OUT:
    #   $result - ������ [0] ������ �������� ������ (�� ������)

    my @result = DBI_EXECUTE_RECORD(@_);
    return $result[0] || '';
}
sub DBI_EXECUTE_RECORD {
    # ��������� ��������� �������� (������, ������)
    # @result = DBI_EXECUTE_RECORD($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $sql - SQL ������
    #   [@inargs] - ��������� ��� ��������
    # OUT:
    #   @result - ������ �������� ������ (�� ������)
    my $sth = DBI_EXECUTE(@_);
    return undef unless $sth;
    my @result = $sth->fetchrow_array;
    $sth->finish;
    return @result;
}
sub DBI_EXECUTE_RECORDH {
    # ��������� ��������� �������� (������, ������) � ���� ����
    # %result = DBI_EXECUTE_RECORDH($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $sql - SQL ������
    #   [@inargs] - ��������� ��� ��������
    # OUT:
    #   %result - ��� �������� ������ (�� ������)
    my $sth = DBI_EXECUTE(@_);
    return undef unless $sth;
    my %result = %{$sth->fetchrow_hashref || {}};
    $sth->finish;
    return %result;
}
sub DBI_EXECUTE_TABLE {
    # ��������� ���� �������� (������� � �� ������ �� �� ��� ������� �� ������ ������)
    # @result = DBI_EXECUTE_TABLE($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $sql - SQL ������
    #   [@inargs] - ��������� ��� ��������
    # OUT:
    #   @result - ������ �������� ������ (�� ������)

    my $sth = DBI_EXECUTE(@_);
    return undef unless $sth;
    my @result = @{$sth->fetchall_arrayref};
    $sth->finish;
    # while (my @tbl_content=$sth->fetchrow_array) {push @result, [@tbl_content]} # ������ �����. �� ������
    return @result;
}
sub DBI_EXECUTE_TABLEH {
    # ��������� ���� �������� (������� � �� ������ �� �� ��� ������� �� ������ ������)
    # %result = DBI_EXECUTE_TABLEH($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $key_field - ����� ������������ (http://search.cpan.org/~timb/DBI-1.607/DBI.pm#fetchall_hashref)
    #   $sql - SQL ������
    #   [@inargs] - ��������� ��� ��������
    # OUT:
    #   Rresult - ��� ����� �������� ������ (�� ������)
    my $dbh       = shift;
    my $key_field = shift;

    my $sth = DBI_EXECUTE($dbh,@_);
    return undef unless $sth;
    my %result = %{$sth->fetchall_hashref($key_field) || {}};
    $sth->finish;
    return %result;
}
sub DBI_EXECUTE {
    # ���������� �������.
    # $sth = DBI_EXECUTE($dbh, $sql, @inargs)
    # IN:
    #   $dbh - DataBase Handler Object
    #   $sql - SQL ������
    #   [@inargs] - ��������� ��� ��������
    # OUT:
    #   $sth_ex - ������ ���������� ��� ����������� ������������� ����������
    
    my $dbh = shift || return 0;
    my $sql = shift || return 0;
 
    my @inargs = ();
    @inargs = @_ if exists $_[0];
    my $argb = "";
    $argb = "Params: ".join(", ", @inargs) if exists $inargs[0];
    
    my $sth_ex = $dbh->prepare($sql);
    unless ($sth_ex) {
        _error("[".__PACKAGE__.": Preparing error: $sql"."] ".$dbh->errstr);
        return undef;
    }
    
    my $count_execute     = 1;     # TRUE
    my $count_execute_msg = 'OK';  # TRUE
    eval {
        local $SIG{ALRM} = sub { die "Executing timeout" } unless $LOAD_SigAction;
        my $h = Sys::SigAction::set_sig_handler( 'ALRM' ,sub { die "Executing timeout" ; } );
        eval {
            alarm(TIMEOUT_REQUEST);
            unless ($sth_ex->execute(@inargs)) {
                $count_execute     = 0; # FALSE
                $count_execute_msg = $dbh->errstr;  # FALSE
            }
            alarm(0);
        };
        alarm(0);
        die $@ if $@;
    };
    if ( $@ ) {
        $count_execute     = 0; # FALSE
        $count_execute_msg = $@;
    }
    unless ($count_execute) {
        # ��� �����
        _error("[".__PACKAGE__.": Executing error: $sql".($argb?" / $argb":'')."] $count_execute_msg");
        return undef;
    }
    
    return $sth_ex || undef;
}
sub _debug { CTK::debug(@_) }
sub _error { carp(@_) }
1;