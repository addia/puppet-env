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
group { 'cdrom' :
  ensure => present,
  gid    => 36
}
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
  gid     => 101,
  members => ['root','addi']
}

# Add the sysadm account
user { 'addi' :
  ensure   => present,
  uid      => 1000,
  gid      => 11,
  password => '$6$MgJRLSON$ld4OjNIMdc9YVNPWfhauERVyoaOaThRaPXQqf2gmnNVNfGqiwCdEgjgiWJpq8HyZ8kbvSGAS2zqlL3ZylIOPk0',
  require  => Group['sysadm']
}

ssh_authorized_key { 'Addis rsa key':
  ensure => present,
  user   => 'addi',
  type   => 'ssh-rsa',
  key    => 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCsFVhM9SHWwUvI6G8ucDAt9swHEoXm17iozlPUfriHBNexXJcjXvB5CLhZGrllqYrikVzicyKUEMPiQU78GKaos0rhoe8IalPGKwbcTaAFHkzBjaOd  9bLpDVv9LAir3gHmfTw8koulmwl3r4AuEv3WdoRCTrddtqq7FmSFOby8yP6Yvt5ELhzpKxTZj4BJSlNQaGWRNVR/ObbIq4Qp6pbLpNh9oqcpZmuzLrURFck7a6TX3nlhgWRK7XYmcxPsR5vpNRVZruRNXQ2fF3mr5xakmqn  H0YK9xhbMdVKF0C3xnkFKpUIp/iXGCIq86Y5IjQCXRZzL7dEoRND68q6docGzq2iZEUSo3fiLGuw50KUFdNUhY8qYxgoX7oL9bprD9TYg5dEyQLRzBxQUon2C0pGLGBdN4gVEmzK+Z0F0malH7i/15EjkE32Y/1fz0L63rG  P9sRo9mRQR5T5ahQlNoBY5j9oJlDYpSNf9hJjFQWYZZuXOzOpUdHI2Qlxykr3Deut5GCzKZWFIlf4c8ZCHoNk9nPT+3YJityCDR5DpI+6a1lG7My3hfkQgFgzv7UrSU3aooY3zRJX7fHRxJagP43uuLVzkjU5rGuCLoVyWM  0BKBwe2O6LxjKuxAh5iUVAZX3prUJu/5qrDG06ZAUrRmy3RW5PrIlq5ZIANPYTWmyl9Yw=='
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

