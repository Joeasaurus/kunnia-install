### Services ###

python::pip {'Attic':
  pkgname => 'attic'
}
file {'/usr/local/bin/attic-wrapper':
  ensure  => present,
  mode    => '0700',
  source  => "${::rundir}/attic-wrapper.sh",
  require => Python::Pip['Attic']
}

docker::image {'centos':
  image_tag => '7'
}