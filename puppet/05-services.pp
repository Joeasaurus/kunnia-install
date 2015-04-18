### Services ###

python::pip {'Attic':
  pkgname => 'attic'
}
docker::image {'centos':
  image_tag => '7',
  notify    => Service['docker']
}