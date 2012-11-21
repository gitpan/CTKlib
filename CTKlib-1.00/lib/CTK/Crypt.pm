package CTK::Crypt; # $Revision: 29 $
use Moose; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::Crypt - Cryptography

=head1 VERSION

1.00

$Id: Crypt.pm 29 2012-11-20 14:50:39Z minus $

=head1 SYNOPSIS

blah-blah-blah

=head1 DESCRIPTION

blah-blah-blah

=cut

use constant {
    # GPG (GNUPG)
    GPGBIN    => 'gpg',
    GPGHOME   => 'gpg',
    CERTDIR   => 'cert',
    PUBRING   => 'public.key',
    SECRING   => 'private.key',
};

use vars qw/$VERSION/;
$VERSION = q/$Revision: 29 $/ =~ /(\d+\.?\d*)/ ? $1 : '1.00';

use CTK::Util qw(:API :FORMAT :UTIL);

sub gpg_decript {
    # Дешифровка файла с помощью команды gpg
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($ifile, $ofile, $gpghome, $certdir, $pubkey, $seckey, $pass);
       ($ifile, $ofile, $gpghome, $certdir, $pubkey, $seckey, $pass) = 
            read_attributes([
                ['IN','FILEIN','INPUT','FILESRC','SRC','INFILE'],
                ['OUT','FILEOUT','OUTPUT','FILEDST','DST','OUTFILE'],
                ['GPGHOME','GPGDIR','DIRGPG','HOMEGPG','GPG'],
                ['CERTDIR','DIRCERT','CERT','CERTS','CRT'],
                ['PUBLIC','PUBLICKEY','PUP','PUBKEY','PUBRING'],
                ['PRIVATE','PRIV','PRIVATEKEY','SEC','SECKEY','SECRET','SECRETKEY','PRIVKEY','PRIVRING','SECRING'],
                ['PASS','PASSWORD','PASSPHRASE'],
            ],@args) if defined $args[0];
    
    return 0 unless $ifile;
    return 0 unless $ofile;
    $gpghome ||= catfile($CTK::DATADIR,GPGHOME);
    $certdir ||= catfile($CTK::DATADIR,CERTDIR);
    $pubkey  ||= catfile($certdir,PUBRING);
    $seckey  ||= catfile($certdir,SECRING);
    $pass      = '' unless defined $pass;
    
    preparedir($gpghome) unless -e $gpghome;
    preparedir($certdir) unless -e $certdir;
    
    my @cmd = (GPGBIN);
    push @cmd, "--lock-multiple";
    push @cmd, "--compress-algo", 1;
    push @cmd, "--cipher-algo", "cast5";
    push @cmd, "--force-v3-sigs";
    push @cmd, "--yes";
    
    unless (CTK::WIN) {
        push @cmd, "--options", CTK::NULL;
        push @cmd, "--homedir", $certdir;
        push @cmd, "--keyring", $pubkey;
        push @cmd, "--secret-keyring",$seckey;
        push @cmd, "--passphrase", $pass if defined $pass;
    }

    push @cmd, "-t";
    push @cmd, "-o", $ofile;
    push @cmd, $ifile;
    push @cmd, CTK::ERR2OUT;
    
    my $rprresult = procexec(\@cmd);
    
    if (-e $ofile) {
        CTK::debug("OK: File GnuPG decription to \"$ofile\"");
        return 1;
    } else {
        CTK::debug("FAILED: File GnuPG decription to \"$ofile\"\n");
        CTK::debug($rprresult);
        carp("FAILED: File GnuPG decription to \"$ofile\"\n$rprresult") unless CTK::debugmode();
        return 0;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__

Домашний каталог: /home/gpg

1. Проверяем, а не имеем ли мы уже установленный сертификат для расшифровки?
 
 gpg --options /dev/null --no-secmem-warning --homedir /home/gpg 
     --keyring /home/gpg/pubring.gpg --secret-keyring /home/gpg/secring.gpg -k

2. Если НЕ имеем, то импортируем его:
 
 gpg --options /dev/null --no-secmem-warning --homedir /home/gpg 
     --keyring /home/gpg/pubring.gpg --secret-keyring /home/gpg/secring.gpg --import /home/gpg/cyberplat.asc
 
3. Далее смотрим опять. Появился?

 gpg --options /dev/null --no-secmem-warning --homedir /home/gpg 
     --keyring /home/gpg/pubring.gpg --secret-keyring /home/gpg/secring.gpg -k
 
4. Снимаем пароль!

 gpg --options /dev/null --no-secmem-warning --homedir /home/gpg 
     --keyring /home/gpg/pubring.gpg --secret-keyring /home/gpg/secring.gpg --edit-key cyberplat

     