package CTK::Net; # $Revision: 33 $
use Moose;
#use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::Net - Network working

=head1 VERSION

1.00

$Id: Net.pm 33 2012-11-21 08:54:56Z minus $

=head1 SYNOPSIS

blah-blah-blah

=head1 DESCRIPTION

blah-blah-blah

=cut

use vars qw/$VERSION/;
$VERSION = q/$Revision: 33 $/ =~ /(\d+\.?\d*)/ ? $1 : '1.00';

use CTK::Util qw(:API :FORMAT :ATOM :FILE);
use URI;
use LWP::UserAgent;
use LWP::MediaTypes qw/guess_media_type media_suffix/;
use HTTP::Request;
use HTTP::Response;
use HTTP::Headers;


sub fetch { # fetch (get, download)
    # Получение файла из удаленного источника по командым:
    # copy     - безприкословное копирование
    # copyuniq - копирование только в случае отсутствия файла
    # move     - удаление после копирования (перенос)
    # moveuniq - Перенос только в случае отсутствия файла
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
    
    $protocol ||= '';     # Протокол: ftp/http/https
    $connect  ||= {};     # Данные соединения
    $command  ||= 'copy'; # Команда: copy / copyuniq / move / moveuniq
    $listmsk  ||= '';     # Список имен файлов для копирования/переноса или маска
    $dirdst   ||= '';     # Директория-приемник
    $mode     ||= '';     # Режим работы: none / ascii / binary (bin)
    $uaopt    ||= {};     # Параметры объека LWP::UserAgent
    
    my $list;
    if ($protocol eq 'ftp') {
        if (ref($listmsk) eq 'ARRAY') {
            # Определенный Список
            $list = $listmsk;
        } elsif (ref($listmsk) eq 'Regexp') { # Regexp
            # Все файлы с ресурса по его Маске
            $list = ftpgetlist($connect,$listmsk);
        } else {
            # Конкретный файл но все равно как маска или же все файлы удаленного ресурса
            $list = ftpgetlist($connect,qr/$listmsk/);
        }
    }
    
    if ($protocol eq 'ftp') {
        CTK::debug("Get files from ftp://$connect->{ftphost}...");
        my $ftph = ftp($connect, 'connect');
        
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fs = $ftph->size($fn) || 0;
            CTK::debug("   Get file $i/$c $fn [".correct_number($fs)." b]...");
            
            my $fndst = catfile($dirdst,$fn);
            
            $ftph->binary if $mode eq 'binary';
            $ftph->binary if $mode eq 'bin';
            $ftph->ascii  if $mode eq 'ascii';
            
            my $statget = 0;
            if (($command =~ /uniq/) && (-e $fndst) && (-s $fndst) == $fs) {
                # Файл уже есть, нет смысла его копировать
                $statget = 1;
                CTK::debug("   --- SKIPPED: Файл уже есть, размеры совпадают, смысла принимать нет!")
            } else {
                $statget = $ftph->get($fn,$fndst);
            }
            
            my $fsdst = $statget && -e $fndst ? (-s $fndst) : 0; # Размер принятого файла
            if ($statget && $fsdst >= $fs) {
                # Все хорошо
                if ($command =~ /move/) {
                    # Удаляем, если у нас перенос файла
                    CTK::debug("   Deleting file $i/$c $fn...");
                    $ftph->delete($fn) or 
                        _error( "   --- ERROR: Can't delete file \"$fn\": ", $ftph->message );
                }
            } else {
                if ($statget) {
                    _error("   --- ERROR: Can't get file \"$fn\": ", $ftph->message); 
                } else {
                    _error("   --- ERROR: File size \"$fn\" ($fs) < \"$fndst\" ($fsdst) ");
                }
            }
        }
        $ftph->quit();
        return 1;
        
    } elsif ($protocol =~ /^https?$/) {
        CTK::exception("Param UAOPT icorrect") if ref($uaopt) ne 'HASH';
        my $ua  = new LWP::UserAgent(%$uaopt); 
        $uacode->($ua) if ($uacode && ref($uacode) eq 'CODE');
        
        # Основные данные из коннекта
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
            _error("ERROR: An error occurred while trying to obtain the resource \"$url\" (",$res->status_line,")");
        }
        
        # Пишем в файл или вывод взад
        # $dirdst  - директория
        # $listmsk - имя файла  
        my $file;
        if ($dirdst || $listmsk) {
            # Строим имя файла на обум
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
            $file = catfile($dirdst,$file) if $dirdst && -e $dirdst; # Задана директория
            
            # Записываем этот монолит в файл на диск
            bsave($file, $html, $onutf8);
            return $res->is_success ? 1 : 0;
            
        } else { 
            # не задано куда сохранять
            return $html;
        }
        
        return 1;
    }
}
sub get { fetch(@_) }
sub download { fetch(@_) }
sub store { # store (put, upload)
    # Отправка файлов на удаленный источник
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
    
    
    $protocol ||= '';     # Протокол
    $connect  ||= {};     # Данные соединения
    $command  ||= 'copy'; # Команда: copy / copyuniq / move / moveuniq
    $listmsk  ||= '';     # Список имен файлов для копирования/переноса или маска
    $dirsrc   ||= '';     # Директория-источник
    $mode     ||= '';     # Режим работы: none / ascii / binary (bin)
    my $list;

    if (ref($listmsk) eq 'ARRAY') {
        # Список
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # Все файлы по его Маске
        $list = getlist($dirsrc,$listmsk);
    } else {
        # Конкретный файл но все равно как маска или же все файлы
        $list = getlist($dirsrc,qr/$listmsk/);
    }

    if ($protocol eq 'ftp') {
        CTK::debug("Store files to ftp://$connect->{ftphost}...");
        my $ftph = ftp($connect,'connect');
        
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fsrc = catfile($dirsrc,$fn);
            my $fs   = -e $fsrc ? (-s $fsrc) : 0; # Размер файла
            CTK::debug("   Store file $i/$c $fn [".correct_number($fs)." b]...");

            $ftph->binary if $mode eq 'binary';
            $ftph->binary if $mode eq 'bin';
            $ftph->ascii  if $mode eq 'ascii';
            my $fsdsta = $ftph->size($fn) || 0; # Размер отправленного файла

            my $statput = 0;
            if (($command =~ /uniq/) && (-e $fsrc) && $fsdsta == $fs) {
                # Файл уже есть, нет смысла его копировать
                $statput = 1;
                CTK::debug("   --- SKIPPED: Файл уже есть, размеры совпадают, смысла отправлять нет!")
            } else {
                $statput = $ftph->put($fsrc,$fn);
            }
            
            my $fsdst = $ftph->size($fn) || 0; # Размер отправленного файла
            if ($statput && $fsdst >= $fs) {
                # Все хорошо
                if ($command eq 'move') {
                    # Удаляем, если у нас перенос файла
                    CTK::debug("   Deleting file $i/$c $fn...");
                    unlink($fsrc) or 
                        _error( "   --- ERROR: Cannot delete file \"$fn\": $!");
                }
            } else {
                if ($statput) {
                    _error("   --- ERROR: Cannot put file \"$fn\": ", $ftph->message); 
                } else {
                    _error("   --- ERROR: File size \"$fn\" ($fsdst) < \"$fsrc\" ($fs) ");
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
	# Возврат в пул данных HTTP
    # debug_http( $response_object )
    # 

	my $res = shift || return '';
	
	return "\n\nREQUEST-HEADERS:\n\n",
	$res->request->method, " ", $res->request->url->as_string,"\n",
	$res->request->headers_as_string,
	"\n\nREQUEST-CONTENT:\n\n",$res->request->content,
	"\n\nRESPONSE:\n\n",$res->code," ",$res->message,"\n",$res->headers_as_string;	
}
sub _error {
    CTK::debug(@_);
    carp(@_) unless CTK::debugmode();
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
