### System ###

## Repos
class {'epel':}

## Disks
class {'autofs':
	source => "${::rundir}/autofs.master",
}
file {'/etc/auto.as3':
	ensure => present,
	source => "${::rundir}/autofs.as3",
	notify => Service['autofs']
}

## Tools
class { 'docker':
  dns => '8.8.8.8',
}