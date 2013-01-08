#########################################################################
#
# Serz Minus (Lepenkov Sergey), <minus@mail333.com>
#
# Copyright (C) 1998-2012 D&D Corporation. All Rights Reserved
# 
# This is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.
#
# $Id: 02-version.t 64 2012-12-27 11:19:15Z minus $
#
#########################################################################
use strict;
use warnings;

use Test::More tests => 10;
use File::Spec;
use YAML;

use CTK;
#$OPT{debug} = 1;

# Go!

my $c = new CTK;
my $ctk_version = $c->VERSION || '';
ok($ctk_version, "CTK version \"$ctk_version\"");


# Reading my files
my @myinc = @INC;
unshift @myinc, File::Spec->rel2abs('..');
unshift @myinc, File::Spec->rel2abs('../lib');
unshift @myinc, map { File::Spec->rel2abs($_) } @myinc;

# Reading CTK.pm File
my $filectk = _find('CTK.pm');
ok $filectk, "CTK.pm file: \"$filectk\"";
my $ctkcontent = CTK::fload($filectk);
my $vsec;
$vsec = $1 if $ctkcontent =~ /version\:?\s*([0-9.]+)/is;
ok $vsec, "Version from section VERSION";
is $vsec, $ctk_version, "CTK Version";
#CTK::debug "VSEC: $vsec";

# Reading README File
my $filereadme = _find('README');
ok $filereadme, "README file: \"$filereadme\"";
my $readmecontent = CTK::fload($filereadme);
my $vsecreadme;
$vsecreadme = $1 if $readmecontent =~ /version\:?\s*([0-9.]+)/is;
ok $vsecreadme, "Version from README";
is $vsecreadme, $ctk_version, "README Version";

# Reading META.yml
my $filemeta = _find('META.yml');
ok $filemeta, "META.yml file: \"$filemeta\"";
my $META = YAML::LoadFile($filemeta);
my $vmeta = '';
if ($META && ref($META) eq 'HASH') {
    foreach my $k (keys %$META) {
        $vmeta = $META->{$k} if $k =~ /^version$/i
    }
}
ok $vmeta, "Version from META.yml";
is $vmeta, $ctk_version, "META.yml Version";

done_testing();

sub _find {
    my $file = shift || '';
    foreach (@myinc) {
        my $f = CTK::catfile($_,$file);
        if ($_ && (-e $f) && -f _) {
            return $f;
        }
    }
    return '';
}