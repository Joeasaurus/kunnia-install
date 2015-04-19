class dldns::collect {
  file {'/bin/r53u':
    ensure => file,
    mode   => '0744',
    owner  => 'root',
    group  => 'root',
    source => 'puppet:///modules/dldns/bin/r53u',
  } ->
  ::Dldns::R53u <<| |>>
}