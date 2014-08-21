autoconf-plugins
================

This repository contains libraries for nagios (or other monitoring system) plugins that are self-documented and allow for auto-configuration.
The aim is to ease integration of new plugins and/or new monitoring point, by proposing to the user a full set of ready-to-use plugin configurations.

For example, if the use choose to monitor the file systems of a newcoming server, the system will be able to propose a full list of filesystem present, and the whole configuration could be done is a few clicks.

Plugins specifications
======================

To achieve this the plugins (whatever the langage they use) should follow these requirements :

Auto-documentation
------------------

When called with the `--autodoc` parameter, the plugin **must** return the following informations :
* Logical name (eg. `CHECK-FEATURE`)
* Version (eg. `1.4`)
* Short plugin description (one line only)
* List of input arguments
  * Logical name (eg. `HOST-IP`)
  * Shortcut (eg. `-H`)
  * Short description
  * Format (string | IP | number | percent | boolean | !regexp!)
  * Mandatory ( states if this argument is mandatory : true/false )
  * Discoverable (states if this argument may be guess in the *autoconf* phase : true/false)
  * UsedForDiscovery (states if this argument is mandatory for the *autoconf* to work : true/false)

Auto-configuration
------------------

If **at least one argument is discoverable**, then the plugin may be called with the `--autoconf` parameter. It then returns the list of possible values for the discoverable arguments, with an additional logical name for each instance.

Example
-------

### check_fs.pl Plugin : Auto-documentation

```bash
$> ./check_fs.pl --autodoc
# Autodoc : format CSV
# Plugin :
# Name;Version;Description
CHECK-FS;1.3;Check filesystem (multi-OS : Linux/Windows)
# Arguments :
# Name;Shortcut;Format;Mandatory;Discoverable;UsedForDiscovery;Description
HOST-IP;H;IP;1;0;1;IP address of host
FILESYSTEM;F;!/([\w\-\.]+/)*[\w\-\.]*|[A-Z]:!;1;1;0;Name of the filesystem
WARNING;w;!\d+[%bkmgt]?!i;0;0;0;Warning threshold (in bytes or %)
CRITICAL;c;!\d+[%bkmgt]?!i;0;0;0;Critical threshold (in bytes or %)
```

### check_fs.pl Plugin : Auto-documentation

```
$> ./check_fs.pl --autoconf -H 192.168.23.45
# Autoconf : format CSV
# Name;HOST-IP;FILESYSTEM;WARNING;CRITICAL
FS-ROOT;192.168.23.45;/;;
FS-BOOT;192.168.23.45;/boot;;
FS-VAR;192.168.23.45;/var;;
FS-HOME;192.168.23.45;/home;;
```

The Plugin may now be tested with one of these arguments :
```
$> ./check_fs.pl -H 192.168.23.45 -F / -w 75% -c 90%
OK : Filesystem / is full at 23% | usage=3547318908 total=15423125687 warning=11567344265 critical=13880813119
```

# General steps of automatic instance definitions

Given these properties for plugins, here are the steps necessary for automatic import :

1. User choose plugin + poller
2. System calls plugin with `--autodoc`
3. User fills in the "used for discovery" fields
4. System calls plugin with `--autoconf`
5. The user is given a list of instances, and may review/modify it before validation
