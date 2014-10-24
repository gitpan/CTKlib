package CTK::Log; # $Revision: 63 $
use Moose::Role; # use Data::Dumper; $Data::Dumper::Deparse = 1;
use Moose::Util::TypeConstraints;

=head1 NAME

CTK::Log - CTK Logging methods

=head1 VERSION

1.00

$Id: Log.pm 63 2012-12-27 11:01:02Z minus $

=head1 SYNOPSIS

    $c = new CTK (
            loglevel     => 'info', # or '1'
            logfile      => CTK::catfile($LOGDIR,'foo.log'),
            logseparator => " ", # as default
        );
        
    $c->log( INFO => " ... Blah-Blah-Blah ... " );

    $c->log_ecept()   # 9 exception
    $c->log_fatal()   # 8 fatal
    $c->log_emerg()   # 7 system is unusable
    $c->log_alert()   # 6 action must be taken immediately
    $c->log_crit()    # 5 critical conditions
    $c->log_error()   # 4 error conditions
    $c->log_warning() # 3 warning conditions
    $c->log_notice()  # 2 normal but significant condition
    $c->log_info()    # 1 informational
    $c->log_debug()   # 0 debug-level messages (default)
    
=head1 DESCRIPTION

All of methods are returned by log-records

=head1 AUTHOR

Serz Minus (Lepenkov Sergey) L<http://serzik.ru> E<lt>minus@mail333.comE<gt>

=head1 COPYRIGHT

Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it under the same terms and conditions as Perl itself.

This program is distributed under the GNU LGPL v3 (GNU Lesser General Public License version 3).

See C<LICENSE> file

=cut

use constant {
    LOGLEVELS       => { 
        'debug'   => 0,
        'info'    => 1,
        'notice'  => 2,
        'warning' => 3,
        'error'   => 4,
        'crit'    => 5,
        'alert'   => 6,
        'emerg'   => 7,
        'fatal'   => 8,
        'except'  => 9,
    },
};

use Data::Dumper;

use vars qw/$VERSION/;
$VERSION = q/$Revision: 63 $/ =~ /(\d+\.?\d*)/ ? $1 : '1.00';

subtype 'LogLevels'
    => as 'Int'
    => where   { $_ >= 0 and $_ <= 9 }
    => message { "The LogLevel $_ not valid" };

coerce 'LogLevels'
    => from 'Str'
    => via { ($_ && LOGLEVELS->{$_}) ? LOGLEVELS->{$_} : 0 };

has 'loglevel' => (
    is         => 'rw', 
    isa        => 'LogLevels', 
    default    => 0,
    lazy       => 1,
    coerce     => 1,
);

has 'logfile' => (
    is         => 'ro', 
    isa        => 'Str', 
    default    => '',
);

subtype 'LogSeparators'
    => as 'Str'
    => where   { defined($_) && $_ ne '' }
    => message { "The logseparator not valid" };

has 'logseparator' => (
    is         => 'rw', 
    isa        => 'LogSeparators', 
    default    => ' ',
    lazy       => 1,
);

subtype 'LogHandler'
    => as 'FileHandle'
    => where   { $_->opened },
    => message { "File's handler do't opened!" };

coerce 'LogHandler'
    => from 'Str'
    => via { FileHandle->new($_,'a') };

has 'handle'   => (
    is         => 'ro',
    isa        => 'LogHandler',
    coerce     => 1,
    predicate  => 'sethandle',
);

around BUILDARGS => sub {
    my $orig = shift;
    my $class = shift;

    #CTK::debug("BUILDARGS called");
    #CTK::debug(Dumper(\@_));

    if ( @_ && ! ref($_[0]) ) {
        my %p = @_;
        unless (defined $p{handle}) {
            # �� ����� �������� handle, ����������� �������� ����, �� logfile, ����� -- ������!
            if (defined $p{logfile}) {
                $p{handle} = $p{logfile};
            }
        }
        return $class->$orig(%p);
    } elsif ( @_ && ref($_[0]) eq 'HASH' ) {
        my $p = $_[0];
        unless (defined $p->{handle}) {
            # �� ����� �������� handle, ����������� �������� ����, �� logfile, ����� -- ������!
            if (defined $p->{logfile}) {
                $p->{handle} = $p->{logfile};
            }
        }
        
    }
    return $class->$orig(@_);

};

after DEMOLISH => sub {
    my $self = shift;

    #CTK::debug("DEMOLISH called");
    
    if ($self->sethandle()) {
        #CTK::debug("DEMOLISH called: handle set !!");
        my $fh = $self->handle;
        $fh->close();
    }
};

sub log {
    my $self  = shift;
    my $level = shift;
    my @l = @_;
    
    my $loglevels = LOGLEVELS;
    my %levels  = %$loglevels;
    my %rlevels = reverse %$loglevels;
    
    my $proc = 'log_debug'; # ���������� �� ���������
    if (defined($level) && ($level =~ /^[0-9]+$/) && defined $rlevels{$level}) {
        $proc = 'log_'.$rlevels{$level};
        #CTK::debug ("FIRST: $proc");
    } elsif (defined($level) && ($level =~ /^[a-z0-9]+$/i) && defined $levels{lc($level)}) {
        $proc = 'log_'.lc($level);
        #CTK::debug ("SECOND: $proc");
    } else {
        unshift @l, $level if defined $level;
        #CTK::debug (@l);
    }
    
    # ��������� ���������� �� ����� ���������
    confess "Undefinned the LogLevel!" unless $proc;
    my $lcode = __PACKAGE__->can("$proc");
    if ($lcode && ref($lcode) eq 'CODE') {
        return $self->$proc(@l); #return &{$lcode}($self,@l);
    } else {
        confess "Can't call method or procedure \"$proc\"!";
    }
    return undef;
}
sub log_debug {
    my $l = "debug";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub logdebug { log_debug @_ }
sub logdebugging { log_debug @_ }
sub info {
    my $l = "info";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub log_info { info @_ } 
sub loginfo { info @_ } 
sub loginformation { info @_ } 
sub loginf { info @_ } 
sub notice {
    my $l = "notice";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub log_notice { notice @_ } 
sub lognotice { notice @_ } 
sub lognote { notice @_ } 
sub warning {
    my $l = "warning";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub log_warning { warning @_ } 
sub logwarning { warning @_ } 
sub logwarn { warning @_ } 
sub error {
    my $l = "error";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub log_error { error @_ } 
sub logerror { error @_ } 
sub crit {
    my $l = "crit";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub log_crit { crit @_ } 
sub logcrit { crit @_ } 
sub logcritical { crit @_ } 
sub alert {
    my $l = "alert";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub log_alert { alert @_ } 
sub logalert { alert @_ } 
sub emerg {
    my $l = "emerg";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub log_emerg { emerg @_ } 
sub logemerg { emerg @_ } 
sub logemergency { emerg @_ } 
sub fatal {
    my $l = "fatal";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub log_fatal { fatal @_ } 
sub logfatal { fatal @_ } 
sub except {
    my $l = "except";
    _flush(LOGLEVELS->{$l}, $l, @_);
}
sub log_except { except @_ } 
sub logexcept { except @_ } 
sub logexception { except @_ } 

sub _flush {
    # ���������� � ���� �����
    my $ilevel = shift;
    my $level  = shift;
    my $self   = shift;
    my @buffer = ();
    local $\;

    return '' if $ilevel < $self->loglevel;

    # ������� �������� ����
    push @buffer, "[".scalar(localtime(time()))."]";
    push @buffer, "[$level]" if defined $level;
    push @buffer, "[$$]";
    
    push @buffer, @_;
    if ($self->sethandle()) {
        my $fh = $self->handle();
        $fh->print(join($self->logseparator(), @buffer),"\n");
    }
    return join($self->logseparator(), @buffer);
}

#no Moose;
#__PACKAGE__->meta->make_immutable;
1;
__END__
