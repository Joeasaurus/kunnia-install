### System ###

## Repos
class {'epel':}

## Disks
class {'autofs':
	template => "${::rundir}/autofs.master.erb",
}
$autoAs3Contents = '
s3-cloud.kunniagaming.net -fstype=fuse,enable_content_md5,retries=10 :s3fs\#cloud\.kunniagaming\.net'
file {'/etc/auto.as3':
	ensure  => present,
	content => $autoAs3Contents,
	notify  => Service['autofs']
}