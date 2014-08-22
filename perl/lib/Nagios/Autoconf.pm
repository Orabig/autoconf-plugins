package Nagios::Autoconf;
use strict;
use warnings;

our $VERSION = "1.00";
 
=head1 NAME
 
Nagios::Autoconf - An utility object for managing arguments and adding auto-conf features to Nagios plugins

=head1 SYNOPSIS

  use Nagios::Autoconf;
  my $plugin = Nagios::Autoconf->new('PLUGIN_NAME', 'PLUGIN_VERSION',
			description => 'PLUGIN_DESCRIPTION'
		);
  $plugin->addArgument('LOGICAL_NAME',
			shortcut => 'SHORTCUT_NAME', 
			format => 'FORMAT',
			mandatory => 'yes/no/true/false/1/0',
			discoverable => 'yes/no/true/false/1/0',
			used_for_discovery => 'yes/no/true/false/1/0',
			description => 'DESCRIPTION'
		);
  $plugin->processArguments;
  
  my $host = $plugin->get('LOGICAL_NAME');

=head1 DESCRIPTION

This is an object-oriented library which helps defining, validating and retrieving arguments for Nagios script.

It also handles auto-documentation and auto-configuration features.

=cut

use Getopt::Long qw(:config no_ignore_case);
 
use Exporter qw(import);
 
our @EXPORT_OK = qw(FORMAT_STRING FORMAT_NUMBER FORMAT_PERCENT FORMAT_IP FORMAT_BOOLEAN exit_normal exit_warning exit_unknown exit_critical);

use constant FORMAT_STRING => '.*';
use constant FORMAT_NUMBER => '\d+';
use constant FORMAT_PERCENT => '(100|\d\d?)\%?';
use constant FORMAT_IP => '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}';
use constant FORMAT_BOOLEAN => '1|0|true|false|yes|no';

my %PLUGIN;
my @ARGUMENTS;

=head2 Methods

=head3 new

  my $plugin = Nagios::Autoconf->new( $PLUGIN_NAME, $PLUGIN_VERSION );
  my $plugin = Nagios::Autoconf->new( $PLUGIN_NAME, $PLUGIN_VERSION, description => $PLUGIN_DESC );

Instantiates an object which holds the plugin properties.

=cut

sub new {
	my($class, $name, $version, %args) = @_;

	my $self = bless({}, $class);
	
	$self->{name} = $name; # TODO : validate logical name
	$self->{version} = $version; # TODO : validate version

	my $description = exists $args{description} ? $args{description} : "$name plugin";
	$self->{description} = $description;
	
	$self->{args} = [];

	return $self;
}

=head3 addArgument

  $plugin->addArgument( $LOGICAL_NAME,
			shortcut => 'SHORTCUT_NAME', 
			format => FORMAT_STRING | FORMAT_IP | FORMAT_NUMBER | FORMAT_PERCENT | FORMAT_BOOLEAN | 'regexp',
			mandatory => boolean,
			discoverable => boolean,
			used_for_discovery => boolean,
			description => 'DESCRIPTION'
		);

Defines a new argument for this plugin. 
The logical name must use only alphanumerical , dash (C<->) or underscore (C<_>) characters.
When unspecified, the shortcut is the initial letter of the logical name (case sensitive !).
When unspecified, the format is FORMAT_NUMBER.
Unless defined, C<mandatory> is set to true, C<discoverable> is set to false and C<used_for_discovery> is set to the opposite of C<discoverable>. 
	
=cut

sub addArgument {
	my $self=shift;
	my($name, %args) = @_;
	my $ARG;
	$ARG->{name}=$name; # TODO : validate logical name
	
	my $defaultShortcut = $name; $defaultShortcut=~s/.*?([a-z]).*/$1/;
	$ARG->{shortcut}= exists $args{shortcut} ? $args{shortcut} : $defaultShortcut;
	$ARG->{format}= exists $args{format} ? $args{format} : FORMAT_NUMBER;
	
	my $mandatory = $args{mandatory};
	my $discoverable = $args{discoverable};
	my $used_for_discovery = $args{used_for_discovery};
	$mandatory = 1 unless defined $mandatory;
	$discoverable = 0 unless defined $discoverable;
	$used_for_discovery = 1-!!$discoverable unless defined $used_for_discovery;
	$ARG->{mandatory}=$mandatory;
	$ARG->{discoverable}=$discoverable;
	$ARG->{used_for_discovery}=$used_for_discovery;
	
	$ARG->{description}= defined $args{description} ? $args{description} : $name;
	
	# Save the argument if both an array and a hash
	push $self->{args}, $ARG;
	$self->{args_by_name}->{$name} = $ARG;
}

=head3 processArguments

  $plugin->processArguments()
  
This function loads the command line arguments, and fills the inner state of the object C<$plugin> with values.

It also returns an error message if some arguments do not meet the requirements (mandatory / format).

=cut

sub processArguments {
	my $self=shift;
	
	# Read the arguments
	my $ARGS_VALUES = {};
	my $autoconf; my $autodoc;
	GetOptions ( 
		"autoconf" => \$autoconf,
		"autodoc"  => \$autodoc ,
		map {
			my $name=$_->{'name'};
			my $short=$_->{'shortcut'};
			"$short:s"=> \$ARGS_VALUES->{$name};
		} @{$self->{args}}
	);
	$self->{values} = $ARGS_VALUES;
	
	# Validate arguments
	foreach my $argument ( @{$self->{args}} ) {
		my $name=$argument->{name};
		my $format=$argument->{format};
		my $shortcut=$argument->{shortcut};
		my $mandatory=$argument->{mandatory};
		my $used_for_discovery=$argument->{used_for_discovery};
		my $value=$self->{values}->{$name};
		if (defined $value && $value eq '') { # Empty argument (like 'b' in '-a 1 -b -c 2')
			$self->{values}->{$name}=$value=undef;
			}
		exit_unknown("$name (-$shortcut) parameter is mandatory") if !defined $value && $mandatory;
		exit_unknown("$name (-$shortcut) parameter is mandatory for --autoconf") if !defined $value && $autoconf && $used_for_discovery;
		exit_unknown("Bad format for $name parameter : -$shortcut $value") unless !defined $value || $value=~/^$format$/;
	}
		
	# Manage --autodoc request
	if ($autodoc) {
		my $plugin_part = join ';', map $self->{$_}, qw!name version description!;
		my $args_in_line = join $/,
			map {
				my $args=$_;
				join ';', map $args->{$_}, qw!name shortcut format mandatory discoverable used_for_discovery description!;
			}
			@{$self->{args}};
	
		exit_unknown(<<AUTODOC_END);
# Autodoc : format CSV

# Plugin :
# Name;Version;Description

$plugin_part

# Arguments :
# Name;Shortcut;Format;Mandatory;Discoverable;UsedForDiscovery;Description

$args_in_line
AUTODOC_END
	}
	
	# TODO : --autoconf
	# ...
} # End of processArguments

=head3 get

  $plugin->get( 'LOGICAL_NAME' );
  
Returns the value of the given argument.
May be C<undefined> if the argument if not mandatory.
Exit with error (3) if the argument is not defined for the plugin

=cut

sub get {
	my $self=shift;
	my $name=shift;
	
	exit_unknown("Plugin error : must call 'processArguments' before 'get'") unless defined $self->{values};
	exit_unknown("Argument '$name' is not defined for this plugin.") unless defined $self->{args_by_name}->{$name};
	my $value = $self->{values}->{$name};	
	return $value;
}

# Nagios output utility methods

sub exit_normal {
	($_)=@_;chomp if defined;
	print "$_\n" if defined $_;
	exit(0);
}
sub exit_warning {
	($_)=@_;chomp if defined;
	print "$_\n" if defined $_;
	exit(1);
}
sub exit_critical {
	($_)=@_;chomp if defined;
	print "$_\n" if defined $_;
	exit(2);
}
sub exit_unknown {
	($_)=@_;chomp if defined;
	print "$_\n" if defined $_;
	exit(3);
}
 
1;