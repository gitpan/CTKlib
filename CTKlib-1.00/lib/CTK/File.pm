package CTK::File; # $Revision: 29 $
use Moose; # use Data::Dumper; $Data::Dumper::Deparse = 1;

=head1 NAME

CTK::File - Files and direcries working

=head1 VERSION

1.00

$Id: File.pm 29 2012-11-20 14:50:39Z minus $

=head1 SYNOPSIS

blah-blah-blah

=head1 DESCRIPTION

blah-blah-blah

For copying paths: use File::Copy::Recursive qw(dircopy dirmove);

For TEMP dirs/files working: use File::Temp qw/tempfile tempdir/;

=cut

use vars qw/$VERSION/;
$VERSION = q/$Revision: 29 $/ =~ /(\d+\.?\d*)/ ? $1 : '1.00';

use CTK::Util qw(:API :FORMAT :ATOM);
use File::Copy;

sub fsplit {
    # ���������� ������ dirin � ���������� �� � ������� dirproc �� ������ ��� ����� � ������ 
    # ���-�� ����� � ����� ����� � �������� ������ (sprintf)
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($dirin, $dirout, $listmsk, $limit, $format);
       ($dirin, $dirout, $listmsk, $limit, $format) = 
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['LIMIT','STRINGS','ROWS','MAX','ROWMAX','N','LIM'],
                ['FORMAT','FMT'],
            ],@args) if defined $args[0];
    
    $dirin    ||= ''; # ������� ����������
    $dirout   ||= ''; # ���������� ���������
    $listmsk  ||= ''; # ������ ���� ������ ��� �������� ��� �����
    $limit    ||=  0; # ����� ����� � �����
    $format   ||= ''; # ������ ���������� ����� (sprintf) ��������: [FILENAME]_%03d.[FILEEXT]
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
    my $c = scalar(@$list) || 0;
    my $i = 0;
    CTK::debug("��������� ������ �������� \"$dirin\" �� ".correct_number($limit)." �����...");
    foreach my $fnin (@$list) {$i++;
        CTK::debug("   ����������� ���� $i/$c $fnin...");
        my $filein = catfile($dirin,$fnin);
        open FIN, "<",$filein or _error("   --- Can't open file $filein: $!") && next;
            my $fpart = 0; # �����
            my $fline = $limit; # ������, ����� (��������!!!)
            open FOUT, ">-";
            while (<FIN>) { # chomp
                if ($fline >= $limit) {
                    # ��������� �����, ����������� �������
                    $fline = 1;
                    $fpart++;
                    my $fformat  = fformat($format,$fnin);
                    my $fnproc   = sprintf($fformat,$fpart); # �������� ���� (���)
                    my $fileproc = catfile($dirout,$fnproc); #  �������� ����
                    CTK::debug("   - ����������� ����� $fpart � ���� $fnproc...");
                    close FOUT;
                    open FOUT, ">", $fileproc or _error("   --- Can't open file $fileproc: $!") && next;
                } else {
                    # �������� ����
                    $fline++;
                }
                print FOUT; # print FOUT "\n";
            }
            close FOUT;
        close FIN or _error("   --- Can't close file $filein: $!");
    }
    
    return 1;
}
sub fcopy {
    # ����������� ������ � ����� ����� � ������ �� ����� ��� ������
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');

    my @args = @_;
    my ($dirin, $dirout, $listmsk, $format);
       ($dirin, $dirout, $listmsk, $format) = 
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['FORMAT','FMT'],
            ],@args) if defined $args[0];

    $dirin    ||= '';     # ����������-��������
    $dirout   ||= '';     # ����������-��������
    $listmsk  ||= '';     # ������ ���� ������ ��� �����������/�������� ��� �����
    $format   ||= '[FILE]'; # ������ ��������� ����� (sprintf). �� ��������� [FILE]
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
    my $c = scalar(@$list) || 0;
    my $i = 0;
    CTK::debug("����������� ������ �������� \"$dirin\" � \"$dirout\"...");
    foreach my $fn (@$list) {$i++;
        CTK::debug("   ���������� ���� $i/$c $fn...");
        copy(catfile($dirin,$fn),catfile($dirout,dformat($format,{FILE=>$fn,COUNT=>$i,TIME=>time()})));
    }
    
    return 1;
}
sub fcp { fcopy(@_) }
sub fmove {
    # ������� ������ � ����� ����� � ������ �� ����� ��� ������
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($dirin, $dirout, $listmsk, $format);
       ($dirin, $dirout, $listmsk, $format) = 
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['DIROUT','OUT','OUTPUT','DIRDST','DST'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
                ['FORMAT','FMT'],
            ],@args) if defined $args[0];

    $dirin    ||= '';     # ����������-��������
    $dirout   ||= '';     # ����������-��������
    $listmsk  ||= '';     # ������ ���� ������ ��� �����������/�������� ��� �����
    $format   ||= '[FILE]'; # ������ ��������� ����� (sprintf). �� ��������� [FILE]
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

    # �� ���� ����� ����� �������� ������ �����  ::debug(join "; ", @$list);
    my $c = scalar(@$list) || 0;
    my $i = 0;
    CTK::debug("������� ������ �������� \"$dirin\" � \"$dirout\"...");
    foreach my $fn (@$list) {$i++;
        CTK::debug("   ����������� ���� $i/$c $fn...");
        move(catfile($dirin,$fn),catfile($dirout,dformat($format,{FILE=>$fn,COUNT=>$i,TIME=>time()})));
    }
    
    return 1;
}
sub fmv { fmove(@_) }
sub fdelete {
    # �������� ������ �� ����� �� ����� ��� ������
    my $self; $self = shift if (@_ && $_[0] && ref($_[0]) eq 'CTK');
    
    my @args = @_;
    my ($dirin, $listmsk);
       ($dirin, $listmsk) = 
            read_attributes([
                ['DIRIN','IN','INPUT','DIRSRC','SRC'],
                ['LISTMSK','LIST','MASK','LST','MSK','FILE','FILES'],
            ],@args) if defined $args[0];
    
    $dirin    ||= '';     # ����������-��������
    $listmsk  ||= '';     # ������ ���� ������ ��� �������� ��� �����
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
    my $c = scalar(@$list) || 0;
    my $i = 0;
    CTK::debug("�������� ������ �������� \"$dirin\"...");
    foreach my $fn (@$list) {$i++;
        CTK::debug("   ��������� ���� $i/$c $fn...");
        unlink(catfile($dirin,$fn));
    }
}
sub fdel { fdelete(@_) }
sub frm { fdelete(@_) }
sub _error {
    CTK::debug(@_);
    carp(@_) unless CTK::debugmode();
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
__END__
