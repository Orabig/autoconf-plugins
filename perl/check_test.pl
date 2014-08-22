#!/usr/bin/perl
use strict;
use warnings;

my $Version = '1.3';
my $PLUGIN_NAME = 'CHECK-FS';
my $PLUGIN_DESC = q!Check filesystem (multi-OS : Linux/Windows)!;
 
use File::Basename qw(dirname);
use Cwd  qw(abs_path);
use lib dirname (abs_path $0) . '/lib';

use Nagios::Autoconf qw(FORMAT_IP FORMAT_NUMBER);

my $plugin = Nagios::Autoconf->new( $PLUGIN_NAME, $Version, description => $PLUGIN_DESC );
$plugin->addArgument('HOST-IP', format=> FORMAT_IP, description=> 'IP address of host (mandatory)');
$plugin->addArgument('FILESYSTEM', shortcut=> 'n'
			, format=> '/([\w\-\.]+/)*[\w\-\.]*|[A-Z]:'
			, description=> 'Name of the filesystem (mandatory)'
			, discoverable=> 1);
$plugin->addArgument('warning', mandatory=>0, description=> 'warning threshold');
$plugin->addArgument('critical', mandatory=>0, description=> 'critical threshold');

$plugin->processArguments();

print "host IP = ".$plugin->get('HOST-IP');

