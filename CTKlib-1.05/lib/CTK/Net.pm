package CTK::Net; # $Id: Net.pm 69 2012-12-28 19:26:44Z minus $
use Moose::Role; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::Net - Network working

=head1 VERSION

Version 1.00

=head1 REVISION

$Revision: 69 $

=head1 SYNOPSIS

    my %ftpct = (
        ftphost     => '192.168.1.1',
        ftpuser     => 'login',
        ftppassword => 'password',
        ftpdir      => '~/dir01',
        #ftpattr     => {},
    );
    
    my %uaopt = (
        agent                   => "Mozilla/4.0",
        max_redirect            => 10,
        requests_redirectable   => ['GET','HEAD','POST'],
        keep_alive              => 1,
        env_proxy               => 1,
    );
    
    my %httpct = (
        method     => 'GET',
        url        => 'http://example.com',
        #login      => 'login',
        #password   => 'password',
        #utf8       => 1,
    );
    
    $c->fetch(
            -connect  => {%ftpct},   # Connect data
            -protocol => 'ftp',      # Protocol: ftp / sftp
            -dir      => $DATADIR,   # Destination directory
            -cmd      => 'copyuniq', # Command: copy / copyuniq / move / moveuniq
            -mode     => 'bin',      # Transfer mode: ascii / binary (bin) 
            -list     => qr//, # Source mask (regular expression, filename or ArrayRef of files)
        );

    my $stat = $c->fetch(
            -connect  => {%httpct},  # Connect data
            -uaopt    => {%uaopt},   # Options UserAgent (optional)
            -protocol => 'http',     # Protocol: http / https
            -dir      => $DATADIR,   # Destination directory
            #-file    => '123.html', # Filename (optional)
            #-uacode  => sub { },    # Handler (code) of LWP::UserAgent (optional)
            #-reqcode => sub { },    # Handler (code) of HTTP::Request (optional)
            #-rescode => sub { },    # Handler (code) of HTTP::Response (optional)
        );
    debug("STATUS: ",$stat); 
    
    # Simple sample
    my $html = $c->fetch(
            -connect  => {
                    method     => 'GET',
                    url        => 'http://google.com/robots.txt',
                },
            -protocol => 'http',
            #-utf8     => 1,
        );
    debug("DATA:\n\n",$html,"\n");
    
    $c->store(
            -connect  => {%ftpct},   # Connect data
            -protocol => 'ftp',      # Protocol: ftp / sftp
            -dir      => $DATADIR,   # Source directory
            -cmd      => 'copyuniq', # Command: copy / copyuniq / move / moveuniq
            -mode     => 'bin',      # Transfer mode: ascii / binary (bin) 
            -file     => 'sample.t', # Source mask (regular expression, filename or ArrayRef of files)
        );

=head1 DESCRIPTION

Using handlers, for sample: 

    -rescode => sub { debug(CTK::Net::_debug_http(@_)) },

    or
    
    -rescode => sub { debug($c->debug_http(@_)) },
    
=head1 TO DO

    * Use SSH (SFTP)

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
$VERSION = q/$Revision: 69 $/ =~ /(\d+\.?\d*)/ ? sprintf("%.2f",($1+100)/100) : '1.00';

use CTK::Util qw(:API :FORMAT :ATOM :FILE);
use URI;
use LWP::UserAgent;
use LWP::MediaTypes qw/guess_media_type media_suffix/;
use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;


sub fetch { # fetch (get, download)
    # ��������� ����� �� ���������� ��������� �� ��������:
    # copy     - ��������������� �����������
    # copyuniq - ����������� ������ � ������ ���������� �����
    # move     - �������� ����� ����������� (�������)
    # moveuniq - ������� ������ � ������ ���������� �����
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($protocol, $connect, $command, $listmsk, $dirdst, $mode, 
        $uaopt,$uacode, $reqcode, $rescode);
       ($protocol, $connect, $command, $listmsk, $dirdst, $mode, 
        $uaopt, $uacode, $reqcode, $rescode) = 
            read_attributes([
                ['PROTOCOL','PROTO'],
                ['CNT','CONNECT','CT'],
                ['CMD','COMMAND','COMAND'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE'],
                ['DESTINATION','DIR','DIRDST','DEST'],
                ['MODE','MD'],
                ['UAOPT','UAOPTS','UAOPTION','UAOPTIONS','UAPARAMS'],
                ['UACODE'],
                ['REQCODE'],
                ['RESCODE'],

            ],@args) if defined $args[0];
    
    $protocol ||= '';     # ��������: ftp/http/https
    $connect  ||= {};     # ������ ����������
    $command  ||= 'copy'; # �������: copy / copyuniq / move / moveuniq
    $listmsk  ||= '';     # ������ ���� ������ ��� �����������/�������� ��� �����
    $dirdst   ||= '';     # ����������-��������
    $mode     ||= '';     # ����� ������: none / ascii / binary (bin)
    $uaopt    ||= {};     # ��������� ������ LWP::UserAgent
    
    my $list;
    if ($protocol eq 'ftp') {
        if (ref($listmsk) eq 'ARRAY') {
            # ������������ ������
            $list = $listmsk;
        } elsif (ref($listmsk) eq 'Regexp') { # Regexp
            # ��� ����� � ������� �� ��� �����
            $list = ftpgetlist($connect,$listmsk);
        } else {
            # ���������� ���� �� ��� ����� ��� ����� ��� �� ��� ����� ���������� �������
            $list = ftpgetlist($connect,qr/$listmsk/);
        }
    }
    
    if ($protocol eq 'ftp') {
        #CTK::debug("Get files from ftp://$connect->{ftphost}...");
        my $ftph = ftp($connect, 'connect');
        
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fs = $ftph->size($fn) || 0;
            #CTK::debug("   Get file $i/$c $fn [".correct_number($fs)." b]...");
            
            my $fndst = catfile($dirdst,$fn);
            
            $ftph->binary if $mode eq 'binary';
            $ftph->binary if $mode eq 'bin';
            $ftph->ascii  if $mode eq 'ascii';
            
            my $statget = 0;
            if (($command =~ /uniq/) && (-e $fndst) && (-s $fndst) == $fs) {
                # ���� ��� ����, ��� ������ ��� ����������
                $statget = 1;
                #CTK::debug("   --- SKIPPED: ���� ��� ����, ������� ���������, ������ ��������� ���!")
            } else {
                $statget = $ftph->get($fn,$fndst);
            }
            
            my $fsdst = $statget && -e $fndst ? (-s $fndst) : 0; # ������ ��������� �����
            if ($statget && $fsdst >= $fs) {
                # ��� ������
                if ($command =~ /move/) {
                    # �������, ���� � ��� ������� �����
                    #CTK::debug("   Deleting file $i/$c $fn...");
                    $ftph->delete($fn) or 
                        _error( "FETCHING FTP ERROR: Can't delete file \"$fn\": ", $ftph->message );
                }
            } else {
                if ($statget) {
                    _error("FETCHING FTP ERROR: Can't get file \"$fn\": ", $ftph->message); 
                } else {
                    _error("FETCHING FTP ERROR: File size \"$fn\" ($fs) < \"$fndst\" ($fsdst) ");
                }
            }
        }
        $ftph->quit();
        return 1;
        
    } elsif ($protocol =~ /^https?$/) {
        CTK::exception("Param UAOPT icorrect") if ref($uaopt) ne 'HASH';
        my $ua  = new LWP::UserAgent(%$uaopt); 
        $uacode->($ua) if ($uacode && ref($uacode) eq 'CODE');
        
        # �������� ������ �� ��������
        my $method   = $connect->{method} || 'GET';
        my $url      = $connect->{url} || '';
        $url         = new URI($url);
        
        my $login    = defined($connect->{login}) ? $connect->{login} : '';
        my $password = defined($connect->{password}) ? $connect->{password} : '';
        my $onutf8   = $connect->{'utf8'} || 0;
        
        my $req = new HTTP::Request(uc($method), $url);
        $req->authorization_basic($login, $password) if defined($connect->{login});
        $reqcode->($req) if ($reqcode && ref($reqcode) eq 'CODE');
        my $res = $ua->request($req);
        $rescode->($res) if ($rescode && ref($rescode) eq 'CODE');
    
        my $html = '';
        if ($res->is_success) {
            if ($onutf8) {
                $html = $res->decoded_content;
                $html = '' unless defined $html;
                Encode::_utf8_on($html);
            } else {
                $html = $res->content;
                $html = '' unless defined $html;
            }
        } else {
            _error("FETCHING HTTP ERROR: An error occurred while trying to obtain the resource \"$url\" (",$res->status_line,")");
        }
        
        # ����� � ���� ��� ����� ����
        # $dirdst  - ����������
        # $listmsk - ��� �����  
        my $file;
        if ($dirdst || $listmsk) {
            # ������ ��� ����� �� ����
            $file = $listmsk || $res->filename;
            unless ($file) {
                my $req = $res->request;  # not always there
                my $rurl = $req ? $req->uri : $url;

                $file = ($rurl->path_segments)[-1];
                if (!defined($file) || !length($file)) {
                    $file = "index";
                    my $suffix = media_suffix($res->content_type);
                    $file .= ".$suffix" if $suffix;
                } elsif ($rurl->scheme eq 'ftp' ||
                    $file =~ /\.t[bg]z$/   ||
                    $file =~ /\.tar(\.(Z|gz|bz2?))?$/
                    ) {
                    # leave the filename as it was
                } else {
                    my $ct = guess_media_type($file);
                    unless ($ct eq $res->content_type) {
                        # need a better suffix for this type
                        my $suffix = media_suffix($res->content_type);
                        $file .= ".$suffix" if $suffix;
                    }
                }
            }
            $file = catfile($dirdst,$file) if $dirdst && -e $dirdst; # ������ ����������
            
            # ���������� ���� ������� � ���� �� ����
            bsave($file, $html, $onutf8);
            return $res->is_success ? 1 : 0;
            
        } else { 
            # �� ������ ���� ���������
            return $html;
        }
        
        return 1;
    }
}
sub get { fetch(@_) }
sub download { fetch(@_) }
sub store { # store (put, upload)
    # �������� ������ �� ��������� ��������
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($protocol, $connect, $command, $listmsk, $dirsrc, $mode);
       ($protocol, $connect, $command, $listmsk, $dirsrc, $mode) = 
            read_attributes([
                ['PROTOCOL','PROTO'],
                ['CNT','CONNECT','CT'],
                ['CMD','COMMAND','COMAND'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE'],
                ['SOURCE','DIR','DIRSRC','SRC'],
                ['MODE','MD']
            ],@args) if defined $args[0];
    
    
    $protocol ||= '';     # ��������
    $connect  ||= {};     # ������ ����������
    $command  ||= 'copy'; # �������: copy / copyuniq / move / moveuniq
    $listmsk  ||= '';     # ������ ���� ������ ��� �����������/�������� ��� �����
    $dirsrc   ||= '';     # ����������-��������
    $mode     ||= '';     # ����� ������: none / ascii / binary (bin)
    my $list;

    if (ref($listmsk) eq 'ARRAY') {
        # ������
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # ��� ����� �� ��� �����
        $list = getlist($dirsrc,$listmsk);
    } else {
        # ���������� ���� �� ��� ����� ��� ����� ��� �� ��� �����
        $list = getlist($dirsrc,qr/$listmsk/);
    }

    if ($protocol eq 'ftp') {
        #CTK::debug("Store files to ftp://$connect->{ftphost}...");
        my $ftph = ftp($connect,'connect');
        
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fsrc = $dirsrc ? catfile($dirsrc,$fn) : $fn;
            my $fs   = -e $fsrc ? (-s $fsrc) : 0; # ������ �����
            #CTK::debug("   Store file $i/$c $fn [".correct_number($fs)." b]...");

            $ftph->binary if $mode eq 'binary';
            $ftph->binary if $mode eq 'bin';
            $ftph->ascii  if $mode eq 'ascii';
            my $fsdsta = $ftph->size($fn) || 0; # ������ ������������� �����

            my $statput = 0;
            if (($command =~ /uniq/) && (-e $fsrc) && $fsdsta == $fs) {
                # ���� ��� ����, ��� ������ ��� ����������
                $statput = 1;
                #CTK::debug("   --- SKIPPED: ���� ��� ����, ������� ���������, ������ ���������� ���!")
            } else {
                $statput = $ftph->put($fsrc,$fn);
            }
            
            my $fsdst = $ftph->size($fn) || 0; # ������ ������������� �����
            if ($statput && $fsdst >= $fs) {
                # ��� ������
                if ($command eq 'move') {
                    # �������, ���� � ��� ������� �����
                    #CTK::debug("   Deleting file $i/$c $fn...");
                    unlink($fsrc) or 
                        _error( "STORING FTP ERROR: Cannot delete file \"$fn\": $!");
                }
            } else {
                if ($statput) {
                    _error("STORING FTP ERROR: Cannot put file \"$fn\": ", $ftph->message); 
                } else {
                    _error("STORING FTP ERROR: File size \"$fn\" ($fsdst) < \"$fsrc\" ($fs) ");
                }
            }
        }
        $ftph->quit();
    }
    
    return 1;
    
}
sub put { store(@_) }
sub upload { store(@_) }
sub _debug_http {
    # ������� � ��� ������ HTTP
    # debug_http( $response_object )
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my $res = shift || return '';
    
    return "\n\nREQUEST-HEADERS:\n\n",
    $res->request->method, " ", $res->request->url->as_string,"\n",
    $res->request->headers_as_string,
    "\n\nREQUEST-CONTENT:\n\n",$res->request->content,
    "\n\nRESPONSE:\n\n",$res->code," ",$res->message,"\n",$res->headers_as_string;	
}
sub _error {
    #CTK::debug(@_);
    carp(@_); #unless CTK::debugmode();
}

#no Moose;
#__PACKAGE__->meta->make_immutable;
1;
__END__
