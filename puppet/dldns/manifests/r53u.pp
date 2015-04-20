# R53u
define dldns::r53u (
  $record
) {
  $default_type = 'CNAME'
  $default_ttl = '900'

  validate_hash($record)
  if(has_key($record, 'recordtype')) {
    $recordtype = $record[recordtype]
  } else {
    $recordtype = $default_type
  }
  if(has_key($record, 'ttl')) {
    $ttl = $record[ttl]
  } else {
    $ttl = $default_ttl
  }
  if (has_key($record, 'zone') and has_key($record, 'localname') and has_key($record, 'recordname')) {
    exec {"r35u[${record[title]}] -> ${record}":
      path    => '/bin:/sbin:/usr/bin',
      command => "r53u create ${record[zone]} ${record[recordname]} ${recordtype} ${record[localname]} ${ttl} --replace --wait",
      unless  => "r53u check ${record[zone]} ${record[recordname]} ${recordtype} ${record[localname]} ${ttl} --replace --wait"
    }
  } else {
    fail("Missing local name, record name or zone:: ${record}")
  }
}