package CTK::Arc; # $Revision: 29 $
use Moose; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::Arc - Archives working

=head1 VERSION

1.00

$Id: Arc.pm 29 2012-11-20 14:50:39Z minus $

=head1 SYNOPSIS

blah-blah-blah

=head1 DESCRIPTION

blah-blah-blah

=cut

use constant {
    ARC       => { 
        tgz   =>  {
            "type"       => "tar",
            "ext"        => "tgz",
            "create"     => "tar -zcpf [FILE] [LIST]",
            "extract"    => "tar -zxpf [FILE] [DIRDST]",
            "exclude"    => "--exclude-from ",
            "list"       => "tar -ztf [FILE]",
            "nocompress" => "tar -cpf [FILE]"
        },
        gz   =>  {
            "type"       => "tar",
            "ext"        => "gz",
            "create"     => "tar -zcpf [FILE] [LIST]",
            "extract"    => "tar -zxpf [FILE] -C [DIRDST]",
            "exclude"    => "--exclude-from ",
            "list"       => "tar -ztf [FILE]",
            "nocompress" => "tar -cpf [FILE]"
        },
        zip   => {    
            "type"       => "zip",
            "ext"        => "zip",
            "create"     => $^O =~ /mswin/i ? "zip -rqq [FILE] [LIST]" : "zip -rqqy [FILE] [LIST]",
            "extract"    => $^O =~ /mswin/i ? "unzip -uqqoX [FILE] -d [DIRDST]" : "unzip -uqqoX [FILE] [DIRDST]", 
            "exclude"    => "-x\@",
            "list"       => "unzip -lqq",
            "nocompress" => "zip -qq0"
        },
        rar   => { 
            "type"       => "rar",
            "ext"        => "rar",
            "create"     => $^O =~ /mswin/i ? "rar a -r -y [FILE] [LIST]" : "rar a -r -ol -y [FILE] [LIST]",
            "extract"    => "rar x -y [FILE] [DIRDST]",
            "exclude"    => "-x\@",
            "list"       => "rar vb",
            "nocompress" => "rar a -m0"
        }
    },
};

use vars qw/$VERSION/;
$VERSION = q/$Revision: 29 $/ =~ /(\d+\.?\d*)/ ? $1 : '1.00';

use CTK::Util qw(:API :FORMAT :ATOM);
use Archive::Tar;
use Archive::Zip qw(:ERROR_CODES :CONSTANTS);
use Archive::Extract;

sub fextract {
    # ���������������� ����������� ���������� ������ ������
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($method, $dirin, $dirout, $listmsk, $arcdef);
       ($method, $dirin, $dirout, $listmsk, $arcdef) = 
            read_attributes([
                ['METHOD','METH','TYPE'],
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['ARC','ARCDEF','ARCSET','SET','DEF'],
                
            ],@args) if defined $args[0];
    
    $method   ||= 'ext'; # ����� ���������� ������ zip / tar / ext
    $dirin    ||= ''; # ������� ����������
    $dirout   ||= ''; # ���������� ����������
    $listmsk  ||= ''; # ������ ���� ������ ��� �������� ��� �����
    $arcdef   ||= ''; # ������ (������ �� ���) ��� ������� ���������� ��������� arc (����� �� ����������)
    my $list;
    
    if (ref($listmsk) eq 'ARRAY') {
        # ������
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # ��� ����� �� ��� �����
        $list = getlist($dirin,$listmsk);
    } else {
        # ���������� ���� �� ��� ����� ��� ����� ��� �� ��� �����
        $list = getlist($dirin,qr/$listmsk/);
    }

    # �� ���� ����� ����� �������� ������ �����
    if ($method eq 'tar') {
        CTK::debug("���������� TAR-������� �������� \"$dirin\" � ������� \"$dirout\"...");
        my $tar = Archive::Tar->new;
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fin = catfile($dirin,$fn);
            my $fs   = -e $fin ? (-s $fin) : 0; # ������ ����� ������
            CTK::debug("   ��������������� ���� $i/$c $fn [".correct_number($fs)." b]...");
            $tar->read($fin);
            foreach my $fan ( $tar->list_files() ) {
                CTK::debug("   --- Extracting \"$fan\"...");
                $tar->extract_file( $fan, catfile($dirout,$fan) );
            }
        
        }
    } elsif ($method eq 'zip') {
        CTK::debug("���������� ZIP-������� �������� \"$dirin\" � ������� \"$dirout\"...");
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fin = catfile($dirin,$fn);
            my $fs   = -e $fin ? (-s $fin) : 0; # ������ ����� ������
            CTK::debug("   ��������������� ���� $i/$c $fn [".correct_number($fs)." b]...");
            my $ae = Archive::Extract->new( archive => $fin );
            my $ok = $ae->extract( to => $dirout );
            if ( $ok ) {
                my $filesok = $ae->files;
                foreach (@$filesok) {CTK::debug("   --- File \"$_\": OK")};
            } else {
                CTK::debug("   --- ERROR: File extract FAILED: ".$ae->error);
                carp("   --- ERROR: File extract FAILED: ".$ae->error) unless CTK::debugmode();
            }
        }
    } elsif ($method eq 'ext') {
        CTK::debug("������� ���������� \"$dirin\" � ������� \"$dirout\"...");
        my $i = 0;
        my $c = scalar(@$list) || 0;
        foreach my $fn (@$list) {$i++;
            my $fin = catfile($dirin,$fn);
            my $fs   = -e $fin ? (-s $fin) : 0; # ������ ����� ������
            CTK::debug("   ��������������� ���� $i/$c $fn [".correct_number($fs)." b]...");
            my $arc = _getarc(
                    FILE     => $fin,
                    FILENAME => $fn,
                    DIRSRC   => $dirin,
                    DIRIN    => $dirin,
                    DIRDST   => $dirout,
                    DIROUT   => $dirout,
                    # EXC    => 'exclude file', # ���������������!!!
                    LIST     => '',
                    ARCDEF   => $arcdef,
                );
            if ($arc) {
                my @C;
                push @C, $arc->{extract};
                #push @C, $fin;
                #push @C, ::WIN &&  $arc->{type} eq 'zip' ? "-d $dirproc" : $dirproc;
                procexec(\@C);
            } else {
                CTK::debug("   --- ERROR: ��������� ���������� ������ ������ �� ����������: $fn");
                carp("   --- ERROR: Unknow format $fn") 
                    unless CTK::debugmode();
            }
        }    
            
    } else {
        CTK::debug("ERROR: ����������� ������ (�����) ������: $method");
        carp("ERROR: Unknow archive's format or method: $method") unless CTK::debugmode();
    }
}
sub fcompress {
    # ������������� ����������� ���������� ������ ����������
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($dirin, $fout, $listmsk, $arcdef);
       ($dirin, $fout, $listmsk, $arcdef) = 
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['FILEOUT','OUT','OUTPUT','FILEDST','DST','FOUT','NAME','ARCHIVE'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['ARC','ARCDEF','ARCSET','SET','DEF'],
                
            ],@args) if defined $args[0];

        
    $dirin    ||= ''; # ������� ���������� (������������ ������� ������!!! - ����� � �����)
    $fout     ||= ''; # ���� ��������� ������ (������ ����)
    $listmsk  ||= ''; # ������ ���� ������ � ��������� ��� �������� ��� ����� ������
    $arcdef   ||= ''; # ������ (������ �� ���) ��� ������� ���������� ��������� arc (����� �� ����������)
    my $list;
    my $dlist;
    
    if (ref($listmsk) eq 'ARRAY') {
        # ������
        $list = $listmsk;
    } elsif (ref($listmsk) eq 'Regexp') { # Regexp
        # ��� ����� �� ��� �����
        $list = getlist($dirin,$listmsk);
        $dlist = getdirlist($dirin,$listmsk);
    } else {
        # ���������� ���� �� ��� ����� ��� ����� ��� �� ��� �����
        $list = getlist($dirin,qr/$listmsk/);
        $dlist = getdirlist($dirin,qr/$listmsk/);
    }
    $list   ||= [];
    $dlist  ||= [];
    
    
    # �� ���� ����� ����� �������� ������ �����  ::debug(join "; ", @$list);
    
    #
    # �������:
    # $arc{create} $bfile ".join(" ",@dirlist)." $exclude ";
    #
    CTK::debug("������� ������ \"$dirin\" � ���� \"$fout\"...");
    my @reallist;
    foreach (@$list,@$dlist) {
        push @reallist, catfile($dirin,$_);
    }

    my $arc = _getarc(
            FILE     => $fout,
            DIRSRC   => $dirin,
            DIRIN    => $dirin,
            # EXC    => 'exclude file', # ���������������!!!
            LIST     => join(" ",@reallist),
            ARCDEF   => $arcdef,
        );
    #use Data::Dumper; ::debug(Dumper($arc)); return 1;
        
    if ($arc) {
        my @C;
        push @C, $arc->{create};
        procexec(\@C);
    } else {
        CTK::debug("   ERROR: ��������� ���������� ������ ������ �� ����������: $fout");
        carp("   ERROR: Format undefined by $fout") unless CTK::debugmode();
    }    
}
sub _getarc {
    # ��������� ��������������� ���� ������ �� ����� ����� ��� undef
    # ������ ������������ ��� � ������ _splitformat
    my %dn = @_;
	my $file = $dn{FILE} || '';
    my $def  = $dn{ARCDEF} || '';
	
    my $ext = ''; 
	$ext = $1 if ($file && $file =~ /\.(\w+)$/);

    my $sec;
    if ($def && $def->{$ext}) {
        $sec = $def->{$ext};
    } else {
        $sec = ARC->{$ext} || undef;
    }
    
    unless( $sec ) {
        CTK::debug( "Error: unknown archive format of file \"$file\": $ext" );
        carp("Error: unknown archive format of file \"$file\": $ext") unless CTK::debugmode();
        return undef;
    }
    my %arc = %$sec;
    
    # ����������� �� ���� ������ ��������� ����
    foreach (values %arc) {
        $_ =~ s/\[(.+?)\]/($dn{uc($1)} || '')/eg;
    }
    
	return {%arc}; # ������ �� ��������� ���
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
