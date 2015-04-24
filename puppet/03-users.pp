### Users ###

file {'/usr/local/bin/addUser':
  ensure  => file,
  source  => "${::rundir}/addUser.sh",
  mode    => '0700'
}