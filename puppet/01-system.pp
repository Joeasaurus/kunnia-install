### System ###

## Repos
class {'epel':}

## DNS
class {'::dldns::install':
  source => "/etc/puppet/modules/dldns/files/bin/r53u"
} ->
::dldns::record {'BaseRecord':
  masterless => true,
  provider   => 'r53',
  record     => {
    zone       => 'cloud.kunniagaming.net',
    ttl        => '300',
    localname  => $::ec2_public_hostname,
    recordname => "c-1"
  }
}

## Tools
class { 'docker':
  dns => '8.8.8.8',
}

## Other stuff
class {'::selinux':
  mode => 'permissive'
}