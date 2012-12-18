#!/usr/bin/perl -w
use strict;
use ExtUtils::MakeMaker;

my $MSWIN = $^O =~ /mswin/i ? 1 : 0;

my $build_requires = {
        'ExtUtils::MakeMaker'   => 6.60,
        'Test::More'            => 0.94,
    };
my $prereq_pm = {
        'ExtUtils::MakeMaker'   => 6.60,
        'File::Spec'            => 0.82,
        'Test::More'            => 0.94,
        'Config::General'       => 2.00,
        'Time::Local'           => 1.20,
        'MIME::Base64'          => 3.00,
        'MIME::Lite'            => 3.00,
        'Net::FTP'              => 2.60,
        'File::Path'            => 2.00,
        'File::Pid'             => 1.00,
        'IPC::Open3'            => 1.00,
        'Term::ReadKey'         => 2.10,
        'IO::Handle'            => 1.20,
        'File::Copy'            => 2.00,
        'Archive::Tar'          => 1.80,
        'Archive::Zip'          => 1.30,
        'Archive::Extract'      => 0.58,
        'Moose'                 => 2.00,
        'namespace::autoclean'  => 0.13,
        'URI'                   => 1.58,
        'LWP'                   => 5.80,
        'LWP::MediaTypes'       => 6.00,
        'LWP::UserAgent'        => 5.80,
        'HTTP::Headers'         => 5.80,
        'HTTP::Request'         => 5.80,
        'HTTP::Response'        => 5.80,
    };
$prereq_pm->{'Sys::SigAction'}  =  0.15 unless $MSWIN;

my $exefiles = [qw(
        bin/ctklib
        bin/ctklib-tiny
    )];
push @$exefiles, (qw(bin/pv.exe)) if $MSWIN;

WriteMakefile(
    'NAME'                  => 'CTK',
    'DISTNAME'              => 'CTKlib',
    'MIN_PERL_VERSION'      => 5.008001,
    'VERSION_FROM'          => 'lib/CTK.pm', 
    'ABSTRACT_FROM'         => 'lib/CTK.pm',
    'BUILD_REQUIRES'        => $build_requires,
    'PREREQ_PM'             => $prereq_pm,
    'EXE_FILES'             => $exefiles,
    'AUTHOR'                => 'Lepenkov Sergey (Serz Minus) <minus@mail333.com>',
    'LICENSE'               => 'lgpl',
    'META_MERGE' => {
        recommends => {
            'DBI'           => 0,
            'Data::Dumper'  => 0,
        },
        resources => {
            homepage        => 'http://serzik.ru',
            repository      => 'http://svn.serzik.ru/CTKlib/trunk',
            license         => 'http://opensource.org/licenses/lgpl-license.php',
        },
    },

);
