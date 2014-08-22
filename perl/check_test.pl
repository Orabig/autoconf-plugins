#!/usr/bin/perl
use strict;
use warnings;

my $Version = '1.3';
my $PLUGIN_NAME = 'CHECK-FS';
my $PLUGIN_DESC = q!Check filesystem (multi-OS : Linux/Windows)!;
 
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname (abs_path $0) . '/lib';

use Nagios::Autoconf qw(initAutoconf);

my %ARGS = initAutoconf("$PLUGIN_NAME;$Version;$PLUGIN_DESC", [
			'HOST-IP;H;IP;1;0;1;IP address of host' ,
			'FILESYSTEM;n;!/([\w\-\.]+/)*[\w\-\.]*|[A-Z]:!;1;1;0;Name of the filesystem' ,
			'WARNING;w;!\d+[%bkmgt]?!i;0;0;0;Warning threshold (in bytes or %)' ,
			'CRITICAL;c;!\d+[%bkmgt]?!i;0;0;0;Critical threshold (in bytes or %)' ]);

# print $ARGS{'HOST-IP'};
# print $ARGS{'WARNING'};
