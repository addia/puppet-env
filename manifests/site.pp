#
# Site Defaults
#

notify{"Server: ${::fqdn}": }
notify{"Network Location: ${::network_location}": }
notify{"Environment: ${::puppet_environment}": }
notify{"Cluster: ${::cluster}": }


# Include all hiera classes
hiera_include('classes')

# fix the host name to lower case ...
exec { 'fix_the_windows_hostname_pants':
  command => 'cat /etc/hosts | tr [:upper:] [:lower:] > /tmp/hh; mv -f /tmp/hh /etc/hosts',
  onlyif  => "grep -v '^#' /etc/hosts | grep -q -e '[[:upper:]]'",
  path    => '/sbin:/bin:/usr/sbin:/usr/bin',
}

# Create 'sysadm' group on all hosts
group { 'sysadm' :
  ensure => present,
  gid    => 11
}

# Configure default sudo behaviour
sudo::conf { 'defaults' :
  priority => 00,
  content  => '#
# Addis default sudoers add-on
#

# Override SSHD configuration file defaults
Defaults            shell_noargs
Defaults            insults
Defaults            !visiblepw
Defaults            requiretty
Defaults            always_set_home
Defaults            mailto      =  "systems@abel.network"
Defaults            env_keep    =  "COLORS DISPLAY HOSTNAME HISTSIZE INPUTRC KDEDIR LS_COLORS"
Defaults            env_keep    += "MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE"
Defaults            env_keep    += "LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES"
Defaults            env_keep    += "LC_MONETARY LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE"
Defaults            env_keep    += "LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY"
Defaults            env_keep    += "HOME"'
}

# Configure password access for 'sudo' group
sudo::conf { 'sudo' :
  priority => 10,
  content  => '#
# Addis sudoers add-on
#

# Custom sudo group access
%sudo  ALL=(ALL) ALL',
}

# Configure passwordless access for 'wireless' group
sudo::conf { 'wireless' :
  priority => 11,
  content  => '#
# Addis sudoers add-on
#

# Custom wireless group access
%wireless  ALL=(ALL) NOPASSWD: ALL',
}

# Configure passwordless access for 'nagios' accout
sudo::conf { 'nagios' :
  priority => 20,
  content  => '#
# Addis sudoers add-on
#

# Custom nagios accout access
nagios  ALL=(ALL) NOPASSWD: ALL',
}

# Configure password access for 'sudo' group
sudo::conf { 'addi' :
  priority => 99,
  content  => '#
# Addis sudoers add-on
#

# Custom sysadmin sudo
Defaults:addi       shell_noargs
Defaults:addi       !always_set_home
Defaults:addi       !requiretty

# Add passwordless sudo for Addi
addi                ALL=(ALL) NOPASSWD: ALL'
}

# Disable root login with password
user { root :
  ensure   => present,
  password => '!'
}

# the sshd protection
group { ssh-users :
  members  => ['root','addi']
}

# Add the sysadm account
user { 'addi' :
  ensure   => present,
  uid      => 1000,
  gid      => 11,
  password => '$6$MgJRLSON$ld4OjNIMdc9YVNPWfhauERVyoaOaThRaPXQqf2gmnNVNfGqiwCdEgjgiWJpq8HyZ8kbvSGAS2zqlL3ZylIOPk0',
  require  => Group['sysadm']
}

# Default executable path
Exec {
  path => '/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin'
}

# Default file permissions to root:root
File {
  owner => 'root',
  group => 'root',
}

# stop allow_virtual parameter from bitching
if versioncmp($::puppetversion,'3.6.1') >= 0 {

  $allow_virtual_packages = hiera('allow_virtual_packages',false)

  Package {
    allow_virtual => $allow_virtual_packages,
  }
}

# Add entry for host in ansible host file
@@file_line { "ansible_host_${::fqdn}":
  line => $::fqdn,
  tag  => 'ansible_hosts'
}

