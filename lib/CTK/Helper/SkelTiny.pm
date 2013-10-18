package CTK::Helper::SkelTiny; # $Id: SkelTiny.pm 162 2013-10-17 09:20:17Z minus $
use strict;

use CTKx;
use CTK::Util qw/ :BASE /;

use vars qw($VERSION);
$VERSION = '1.00';

sub build {
    # Процесс сборки
    my $self = shift;
    return 1;
}
sub pool {
    # Бассеин с разделенными multipart файламми
    my $pos =  tell DATA;
    my $data = scalar(do { local $/; <DATA> });
    seek DATA, $pos, 0;
    return $data;
}

1;
__DATA__

-----BEGIN FILE-----
Name: %PROJECTNAME%.pl
File: %PROJECTNAME%.pl
Mode: 777

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
-----END FILE-----
