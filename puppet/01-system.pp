### System ###

## Repos
class {'epel':}

## DNS
class {'::dldns::install':
	source => "/etc/puppet/modules/dldns/files/bin/r53u"
} ->
::dldns::record {'BaseRecord':
	masterless => true,
	provider 	 => 'r53',
	record     => {
		zone       => 'cloud.kunniagaming.net',
    ttl        => '300',
    localname  => $::ec2_public_hostname,
    recordname => "c-1"
	}
}

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