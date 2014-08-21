package Nagios::Autoconf;
use strict;
use warnings;

use Getopt::Long qw(:config no_ignore_case);
 
use Exporter qw(import);
 
our @EXPORT_OK = qw(declareArgs);

my %PLUGIN;
my @ARGUMENTS;

# This function must be called at the start of the script
sub declareArgs {
  my ($_) = @_;
  my $format = $1 if /# *Autodoc *: *format +(\w+)/i;
  my ($plugin_part, $args_part)=split /# *Arguments *:? */;
  $plugin_part=~s/^(#.*|$)\n*//mg;
  $args_part=~s/^(#.*|$)\n*//mg;
  ($PLUGIN{'NAME'},$PLUGIN{'VERSION'},$PLUGIN{'DESC'})=split /;/, $plugin_part;
  @ARGUMENTS = map {
	my %ARG;
	($ARG{'NAME'},$ARG{'SHORTCUT'},$ARG{'FORMAT'},$ARG{'MANDATORY'},$ARG{'DISCO'},$ARG{'USED'},$ARG{'DESC'}) = split /;/;
	\%ARG;
	} split $/, $args_part;
	
	# Read the arguments
	my $ARGS_VALUES = {};
	GetOptions map {
		my $name=$_->{'NAME'};
		my $short=$_->{'SHORTCUT'};
		"$short:s"=>\$ARGS_VALUES->{$name};
		} @ARGUMENTS;
		
	%$ARGS_VALUES;
}
 
1;