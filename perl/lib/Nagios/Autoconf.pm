package Nagios::Autoconf;
use strict;
use warnings;

####### TODO : --version and --help

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
my $OUTPUT_SEP=';';
my $INSTANCE_NAME='INSTANCE_NAME'; # Reserved word for autoconf output

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
	$self->{confs} = [];

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
Unless defined, C<mandatory> is set to B<TRUE>, C<discoverable> is set to B<FALSE>.
Unless defined, C<used_for_discovery> is to B<TRUE> only if the argument is C<mandatory> and not C<discoverable>. 
	
=cut

sub addArgument {
	my $self=shift;
	my($name, %args) = @_;
	my $ARG;
	$ARG->{name}=$name; # TODO : validate logical name
	
	my $defaultShortcut = $name; $defaultShortcut=~s/.*?([a-z]).*/$1/i;
	$ARG->{shortcut}= exists $args{shortcut} ? $args{shortcut} : $defaultShortcut;
	$ARG->{format}= exists $args{format} ? $args{format} : FORMAT_NUMBER;
	
	my $mandatory = $args{mandatory};
	my $discoverable = $args{discoverable};
	my $used_for_discovery = $args{used_for_discovery};
	$mandatory = 1 unless defined $mandatory;
	$discoverable = 0 unless defined $discoverable;
	$used_for_discovery = 1-!($mandatory && !$discoverable) unless defined $used_for_discovery;
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
	my $autoconf; my $autodoc; my $commandline;
	GetOptions ( 
		"autoconf" => \$autoconf,
		"commandline" => \$commandline,
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
		unless ($autodoc) {
			exit_unknown("$name (-$shortcut) parameter is mandatory") if !defined $value && $mandatory && !$autoconf ;
			exit_unknown("$name (-$shortcut) parameter is mandatory for --autoconf") if !defined $value && $autoconf && $used_for_discovery;
			exit_unknown("Bad format for $name parameter : -$shortcut $value") unless !defined $value || $value=~/^$format$/;
		}
	}
		
	# Manage --autodoc request
	if ($autodoc) {
		my $plugin_part = join $OUTPUT_SEP, map $self->{$_}, qw!name version description!;
		my $args_in_line = join $/,
			map {
				my $args=$_;
				join $OUTPUT_SEP, map $args->{$_}, qw!name shortcut format mandatory discoverable used_for_discovery description!;
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
	
	$self->{autoconf}=$autoconf;
	$self->{commandline}=$commandline;
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

=head3 autoconf

  $plugin->autoconf( sub{ ... $plugin.set() ... $plugin.suggest()... } );
  
Makes the autoconf
=cut

sub autoconf {
	my $self=shift;
	my $function=shift;
	return unless $self->{autoconf};
	$function->(); # This is supposed to push configs to {confs}
	
	# Extract the list of arguments logical names in order
	my @NAMES=map $_->{name}, @{ $self->{args} };
	# Two different formats for autoconf : CommandLine or CSV output
	if ( $self->{commandline} ) {
		# Generate a command line
		my @params = map{
			my $values=$_;
			join $", map "-$self->{args_by_name}->{$_}->{shortcut} $values->{$_}", @NAMES;
		} @{ $self->{confs} };
		print "# Autoconf : command lines\n".join $/, map "$0 $_",@params;
		print $/;
	} else {
		my $header = join $OUTPUT_SEP, $INSTANCE_NAME, @NAMES;
		my $count=1;
		my $proposals = join $/,map{
			my $values=$_;
			my $instanceName = $values->{$INSTANCE_NAME};
			$instanceName=$self->{name}."-$count" unless $instanceName; $count++;
			$instanceName . $OUTPUT_SEP . join $OUTPUT_SEP, map $values->{$_}, @NAMES;
		} @{ $self->{confs} };
		exit_unknown(<<AUTOCONF_END);
# Autoconf : format CSV

# $header
$proposals
AUTOCONF_END
		}
	}

sub set {
	my $self=shift;
	my $name=shift;
	my $value=shift;
	$self->{values}->{$name}=$value;
}

sub suggest {
	my $self=shift;
	my $instanceName=shift;
	my %copy = %{$self->{values}};
	$copy{$INSTANCE_NAME}=$instanceName;
	push $self->{confs}, \%copy;
}

sub save {
	my $self=shift;
	my %copy = %{$self->{values}};
	$self->{saved_values}=\%copy;
}

sub load {
	my $self=shift;
	my $copy = $self->{saved_values};
	$self->{values} = $copy if $copy;
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