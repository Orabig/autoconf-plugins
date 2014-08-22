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

$plugin->autoconf( sub {
	# Do whatever this plugin can do to suggest some useful configurations
	$plugin->set('FILESYSTEM','/');    $plugin->suggest("FS-ROOT");
	$plugin->set('FILESYSTEM','/home');$plugin->suggest("FS-HOME");
	
	$plugin->save(); # Some argument values will be changed. Let's save them before that...
	$plugin->set('warning',90); $plugin->set('critical',95);
	$plugin->set('FILESYSTEM','/tmp'); $plugin->suggest("FS-TEMP");
	$plugin->load(); # ...Then load them after
	
	$plugin->set('FILESYSTEM','/dev'); $plugin->suggest("FS-DEV");
} );


#print "host IP = ".$plugin->get('HOST-IP');

