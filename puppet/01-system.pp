### System ###

## Repos
class {'epel':}

## Disks
class {'autofs':
	template => "${::rundir}/autofs.master.erb",
}
file {'/etc/auto.as3':
	ensure  => present,
	content => template("${::rundir}/autofs.as3.erb"),
	notify  => Service['autofs']
}

## Tools
class { 'docker':
  dns => '8.8.8.8',
}