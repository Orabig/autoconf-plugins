package Nagios::Autoconf;
use strict;
use warnings;

use Getopt::Long qw(:config no_ignore_case);
 
use Exporter qw(import);
 
our @EXPORT_OK = qw(initAutoconf);

my %PLUGIN;
my @ARGUMENTS;

# This function must be called at the start of the script
# It takes 2 arguments :
#    The plugin description part, which is a string in format : "PLUGIN_NAME;PLUGIN_VERSION;PLUGIN_DESCRIPTION"
#    An array of Argument description in format "LOGICAL_NAME;ARGUMENT_NAME;FORMAT;MANDATORY;DISCOVERABLE;USED_FOR_DISCO;DESCRIPTION"
sub initAutoconf {
  my ($plugin_part, $args_part) = @_;
  ($PLUGIN{'NAME'},$PLUGIN{'VERSION'},$PLUGIN{'DESC'})=split /;/, $plugin_part;
  @ARGUMENTS = map {
	my %ARG;
	($ARG{'NAME'},$ARG{'SHORTCUT'},$ARG{'FORMAT'},$ARG{'MANDATORY'},$ARG{'DISCO'},$ARG{'USED'},$ARG{'DESC'}) = split /;/;
	\%ARG;
	} @$args_part;
	
	# Read the arguments
	my $ARGS_VALUES = {};
	my $autoconf; my $autodoc;
	GetOptions ( 
		"autoconf" => \$autoconf,
		"autodoc"  => \$autodoc ,
		map {
			my $name=$_->{'NAME'};
			my $short=$_->{'SHORTCUT'};
			"$short:s"=>\$ARGS_VALUES->{$name};
		} @ARGUMENTS );
		
	# Manage --autodoc request
	if ($autodoc) {
		my $args_in_line = join $/,@$args_part;
		print <<AUTODOC_END;
# Autodoc : format CSV

# Plugin :
# Name;Version;Description

$plugin_part

# Arguments :
# Name;Shortcut;Format;Mandatory;Discoverable;UsedForDiscovery;Description

$args_in_line

AUTODOC_END
	exit_unknown();
	}
		
	%$ARGS_VALUES;
}

sub exit_unknown {
	my ($output)=@_;
	print $output if defined $output;
	exit(3);
}
 
1;